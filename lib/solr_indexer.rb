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

    def initialize(url, domain_names = {})
      @solr = RSolr.connect url:, adapter: :net_http_persistent
      @domain_names = domain_names
    end

    def update(file_path)
      commit_within = ENV.fetch('SOLR_COMMIT_WITHIN', 5000).to_i
      doc = JSON.parse(File.read(file_path))
      [doc].flatten.each do |record|
        update_domains!(record) unless @domain_names.empty?
        @solr.update params: { commitWithin: commit_within, overwrite: true },
                     data: [record].to_json,
                     headers: { 'Content-Type' => 'application/json' }
      end
    end

    def update_domains!(record)
      references = record['dct_references_s']
      Config.domain_names.each do |name, from_domain|
        to_domain = @domain_names[name.to_s]
        references.gsub(from_domain, to_domain) if to_domain
      end
      record['reference'] = references
    end
  end
end
