# frozen_string_literal: true

require 'rsolr'
require 'faraday/net_http_persistent'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config
  # index solr for Gingr
  class SolrIndexer
    attr_reader :solr

    # for updating reference field url domains
    @download_url = ENV.fetch('DOWNLOAD_URL')
    @geoserver_url = ENV.fetch('GEOSERVER_URL')
    @geoserver_secure_url = ENV.fetch('GEOSERVER_SECURE_URL')
    class << self
      attr_accessor :download_url, :geoserver_url, :geoserver_secure_url
    end

    def initialize(url)
      @solr = RSolr.connect url:, adapter: :net_http_persistent
    end

    def update(file_path, update_reference_field)
      commit_within = ENV.fetch('SOLR_COMMIT_WITHIN', 5000).to_i
      doc = JSON.parse(File.read(file_path))
      [doc].flatten.each do |record|
        update_domains!(record) if update_reference_field
        @solr.update params: { commitWithin: commit_within, overwrite: true },
                     data: [record].to_json,
                     headers: { 'Content-Type' => 'application/json' }
      end
    end

    def update_domains!(record)
      references = record['dct_references_s']
      Config.name_domain_hash.each do |name, from_domain|
        to_domain = get_domain(name)
        references.gsub(from_domain, to_domain) unless to_domain.nil?
      end
      record['reference'] = references
    end

    def get_domain(name)
      url = SolrIndexer.send(name)
      return nil if url.nil?

      uri = URI.parse(url)
      uri.host
    end
  end
end
