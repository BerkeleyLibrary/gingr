# frozen_string_literal: true
require 'faraday/net_http_persistent'
require 'find'
require 'rsolr'
require_relative 'config'

module Gingr
  class SolrIndexer
    include Logging

    attr_accessor :reference_urls, :solr

    # attr_accessor :solr

    def initialize(connection = nil, refurls = nil)
      connection ||= Gingr::Config.getopt(:solr_url)
      connection = RSolr.connect url: connection, adapter: :net_http_persistent if connection.kind_of? String
      @solr = connection

      # Strip HTTP Basic Auth
      @reference_urls = (refurls || {}).transform_values do |url|
        URI(url).tap { |uri| uri.password = uri.user = nil }.to_s
      end
    end

    def add(doc)
      doc = JSON.load_file(doc) if doc.kind_of? String

      logger.debug("Indexing document: #{doc['id']}")
      update_reference_urls!(doc)
      @solr.add doc
    rescue StandardError => e
      logger.error "Indexing document '#{doc['id']}' failed: #{e.message}"
      raise
    end

    # def index_directory(directory)
    #   Find.find(directory)
    #     .select(&method(:json_file?))
    #     .each(&method(:add))
    #   @solr.commit
    # end

    def index_directory(directory)
      total_indexed = Find.find(directory)
                          .select(&method(:json_file?))
                          .each(&method(:add))
                          .size
      @solr.commit
      total_indexed
    rescue StandardError => e
      logger.error "Indexing directory '#{directory}' failed: #{e.message}"
      nil
    end

    def update_reference_urls!(doc)
      Gingr::Config.reference_urls.each do |name, from_url|
        to_url = @reference_urls[name]

        if doc.key?('dct_references_s') && to_url
          logger.debug("Updating dct_references_s from #{from_url} to #{to_url}")
          doc['dct_references_s'].gsub!(from_url, to_url)
        end
      end
    end

    def json_file?(filepath)
      File.extname(filepath).casecmp?('.json')
    end
  end
end
