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

    # # for updating reference field url domains from json file
    # @download_url = ENV.fetch('DOWNLOAD_URL')
    # @geoserver_url = ENV.fetch('GEOSERVER_URL')
    # @geoserver_secure_url = ENV.fetch('GEOSERVER_SECURE_URL')
    # class << self
    #   attr_accessor :download_url, :geoserver_url, :geoserver_secure_url
    # end

    def initialize(url, options = {})
      @solr = RSolr.connect url:, adapter: :net_http_persistent
      @options = options
      # unless options.empty?

      # # @update_reference_field = options[:update_reference_field]
      # @download_url = options[:download_url]
      # @geoserver_url = ENV.fetch('GEOSERVER_URL')
      # @geoserver_secure_url = ENV.fetch('GEOSERVER_SECURE_URL')
    end

    def update(file_path, _update_reference_field)
      commit_within = ENV.fetch('SOLR_COMMIT_WITHIN', 5000).to_i
      doc = JSON.parse(File.read(file_path))
      [doc].flatten.each do |record|
        update_domains!(record) unless @options.empty?
        @solr.update params: { commitWithin: commit_within, overwrite: true },
                     data: [record].to_json,
                     headers: { 'Content-Type' => 'application/json' }
      end
    end

    def update_domains!(record)
      # new_download_url = options[:download_url]
      # @geoserver_url = ENV.fetch('GEOSERVER_URL')
      # @geoserver_secure_url = ENV.fetch('GEOSERVER_SECURE_URL')

      references = record['dct_references_s']
      Config.domain_names_hash.each do |name, from_domain|
        to_domain = @options[name.to_s]
        references.gsub(from_domain, to_domain) if to_domain
      end
      record['reference'] = references
    end

    # def get_domain(name)
    #   url = SolrIndexer.send(name)
    #   return nil if url.nil?

    #   uri = URI.parse(url)
    #   uri.host
    # end

    # def get_domain(name)
    #   url = SolrIndexer.send(name)
    #   return nil if url.nil?

    #   uri = URI.parse(url)
    #   uri.host
    # end
  end
end
