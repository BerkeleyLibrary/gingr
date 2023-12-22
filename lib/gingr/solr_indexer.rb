# frozen_string_literal: true
require 'faraday/net_http_persistent'
require 'find'
require 'rsolr'
require_relative 'config'

module Gingr
  class SolrIndexer
    include Config

    attr_accessor :reference_urls
    attr_accessor :solr

    def initialize(solr = nil, reference_urls = nil)
      solr ||= ENV['SOLR_URL'] || Gingr::Config.default_options[:solr_url]
      solr = RSolr.connect url: solr, adapter: :net_http_persistent if solr.kind_of? String
      @solr = solr
      @reference_urls = reference_urls || {}
    end

    def add(doc)
      doc = JSON.load_file(doc) if doc.kind_of? String
      update_reference_urls!(doc)
      @solr.add doc
    end

    def index_directory(directory)
      Find.find(directory)
        .select(&method(:json_file?))
        .each(&method(:add))
    end

    def update_reference_urls!(doc)
      Gingr::Config.reference_urls.each do |name, from_url|
        to_url = @reference_urls[name]
        doc['dct_references_s'].gsub!(from_url, to_url) if doc.key?('dct_references_s') && to_url
      end
    end

    def json_file?(filepath)
      File.extname(filepath).casecmp?('.json')
    end
  end
end
