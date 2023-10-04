# frozen_string_literal: true

# require 'net/http'
# require 'json'
require 'rsolr'
# require 'find'
require 'faraday/net_http_persistent'

module Gingr
  # index solr for Gingr
  class Indexer
    attr_reader :solr
    attr_reader :reference_urls 

    def self.reference_urls(hash)
      @reference_urls = hash
    end

    def initialize(url)
      @solr = RSolr.connect url:, adapter: :net_http_persistent
    end

    def update(file_path)
      commit_within = 5000
      doc = JSON.parse(File.read(file_path))
      update_reference(doc)
      solr.update params: { commitWithin: commit_within, overwrite: true },
                  data: doc.to_json,
                  headers: { 'Content-Type' => 'application/json' }
    end

    def update_reference(doc)
      geoserver_secure_url_production = 'a'
      geoserver_url_production = 'b '
      geoserver_secure_url = ENV.fetch('GEOSERVER_SECURE_URL', 'http://admin:geoserver@geoserver:8080/geoserver/rest/')
      geoserver_url = ENV.fetch('GEOSERVER_URL', 'http://admin:geoserver@geoserver:8080/geoserver/rest/')
      reference = doc['dct_references_s']
      reference_updated = reference.gsub(geoserver_secure_url, geoserver_secure_url_production) \
                                   .gsub(geoserver_url, geoserver_url_production)
      doc['reference'] = reference_updated
    end
  end
end
