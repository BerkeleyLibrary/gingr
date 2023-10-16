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

    def initialize(url)
      @solr = RSolr.connect url:, adapter: :net_http_persistent
    end

    def update(file_path, change_reference_domain)
      commit_within = ENV.fetch('SOLR_COMMIT_WITHIN', 5000).to_i
      doc = JSON.parse(File.read(file_path))
      [doc].flatten.each do |record|
        update_domains!(record) if change_reference_domain
        @solr.update params: { commitWithin: commit_within, overwrite: true },
                     data: [record].to_json,
                     headers: { 'Content-Type' => 'application/json' }
      end
    end

    def update_domains!(record)
      references = record['dct_references_s']
      Config.env_domains.each do |env, domain|
        to_domain = domain(env)
        references.gsub(domain, to_domain) unless to_domain.nil?
      end
      record['reference'] = references
    end

    def domain(env)
      url = ENV.fetch(env)
      return nil if url.nil?

      uri = URI.parse(url)
      uri.host
    end
  end
end
