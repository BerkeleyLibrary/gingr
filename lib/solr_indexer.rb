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

    def initialize(url, reference_urls = {})
      @solr = RSolr.connect url:, adapter: :net_http_persistent
      @reference_urls = reference_urls
      @need_update_reference_urls = !@reference_urls.empty?
    end

    def update(file_path)
      commit_within = ENV.fetch('SOLR_COMMIT_WITHIN', 5000).to_i
      doc = JSON.parse(File.read(file_path))
      [doc].flatten.each do |record|
        update_reference_urls!(record) if @need_update_reference_urls
        puts record
        @solr.update params: { commitWithin: commit_within, overwrite: true },
                     data: [record].to_json,
                     headers: { 'Content-Type' => 'application/json' }
      end
    end

    private

    def update_reference_urls!(record)
      references = record['dct_references_s']

      Config.reference_urls.each do |name, from_url|
        to_url = @reference_urls[name.to_s]
        references = references.gsub(from_url, to_url) if to_url
      end
      record['dct_references_s'] = references
    end

    # def update_reference_urls!(record)
    #   puts('inin')
    #   references = record['dct_references_s']
    #   puts references.class
    #   Config.reference_urls.each do |name, from_url|
    #     puts name
    #     to_url = @reference_urls[name.to_s]
    #     puts from_url
    #     puts to_url
    #     # references.gsub(from_url, to_url) if to_url
    #     references.gsub(from_url, to_url)
    #   end
    #   puts references
    #   record['dct_references_s'] = references

    #   # puts record
    # end
  end
end
