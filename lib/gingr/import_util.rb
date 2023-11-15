# frozen_string_literal: true
require 'find'
require 'uri'
require_relative 'config'
require_relative 'geoserver_publisher'
require_relative 'solr_indexer'

module Gingr
  module ImportUtil
    include Gingr::Config

    class << self
      def publish_geoservers(geofile_names, options)
        publish_geoserver_files(geofile_names[:public], options[:geoserver_url], true)
        publish_geoserver_files(geofile_names[:ucb], options[:geoserver_secure_url], false)
      end

      def index_solr_from_dir(directory_path, url, reference_urls)
        indexer = SolrIndexer.new(url, reference_urls)
        Find.find(directory_path) do |path|
          next unless File.extname(path).downcase == '.json'

          indexer.update(path)
        rescue RSolr::Error::Http => e
          Config.logger.error("Solr index error: #{e.response}")
          raise
        end
        indexer.commit
      end

      def get_reference_urls(options)
        update_reference_field = options[:update_reference_field]
        return {} unless update_reference_field

        hash = {}
        Config.reference_urls.each_key do |key|
          url = options[key] || ENV.fetch(key.to_s.upcase)
          hash[key] = reference_url(url) if url
        end
        hash
      end

      def root_path
        File.expand_path('..', __dir__)
      end

      private

      def publish_geoserver_files(files, url, is_public)
        return if files.empty?

        url ||= is_public ? ENV.fetch('GEOSERVER_URL', nil) : ENV.fetch('GEOSERVER_SECURE_URL', nil)
        publisher = GeoserverPublisher.new(url)
        publisher.batch_update(files)
      end

      def reference_url(url)
        uri = URI(url)
        uri_port = uri.port.to_s
        port = uri_port.start_with?('80') ? ":#{uri_port}" : ''
        "#{uri.scheme}://#{uri.host}#{port}"
      end
    end
  end
end
