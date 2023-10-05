# frozen_string_literal: true

require 'rsolr'
require 'json'
require 'faraday/net_http_persistent'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config
  # index solr for Gingr
  class Indexer
    attr_reader :solr

    def initialize(url)
      puts(url)
      url = "http://localhost:8983/solr/#/geodata-test"
      @solr = RSolr.connect url:, adapter: :net_http_persistent
    end

    def update(file_path, _update_domain)
      commit_within = 500
      doc = JSON.parse(File.read(file_path))
      # puts(doc)
      # update_domains(doc) if update_domain
      # @solr.update params: { commitWithin: commit_within, overwrite: true },
      #             data: doc.to_json,
      #             headers: { 'Content-Type' => 'application/json' }
    end

    def update_domains(doc)
      references = doc['dct_references_s']
      Config.domains.each do |k, v|
        # puts(v)
        t_v = domain(ENV[k.to_s])
        references.gsub(v, t_v) unless t_v.nil?
      end
      doc['reference'] = references
    end

    def domain(url)
      return '' if url.nil?

      uri = URI.parse(url)
      uri.host
    end
  end
end
