# frozen_string_literal: true

require 'rsolr'
require 'faraday/net_http_persistent'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config
  # index solr for Gingr
  class Indexer
    attr_reader :solr

    def initialize(url)
      @solr = RSolr.connect url:, adapter: :net_http_persistent
    end
 

    def update(file_path, update)
      commit_within = 5000
      doc = JSON.parse(File.read(file_path))
      [doc].flatten.each do |record|
        # puts("updating")
        # puts record.class.name
        update_domains!(record) if update
        # puts record
        @solr.update params: { commitWithin: commit_within, overwrite: true },
                    data: [record].to_json,
                    headers: { 'Content-Type' => 'application/json' }
      end
    end

    def update_domains!(record)
      references = record['dct_references_s']
      Config.domains.each do |k, v|
        puts(k.to_s)
        i = k.to_s
        puts i
        name = "#{ENV[i]}_URL"
        puts name
        # puts(v)
        # puts(k.to_s)
        t_v = self.domain("#{ENV[k.to_s]}_URL")
        puts t_v
        references.gsub(v, t_v) unless t_v.nil?
      end
      record['reference'] = references
      
    end

    def domain(url)
      return '' if url.nil?
      
      puts url
      uri = URI.parse(url)
      uri.host
    end
  end
end
