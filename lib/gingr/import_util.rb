# frozen_string_literal: true

require 'find'
require 'uri'
require_relative 'config'
require_relative 'geoserver_publisher'
require_relative 'logging'
require_relative 'solr_indexer'

module Gingr
  module ImportUtil
    include Config
    include Logging

    class << self
      def publish_geoservers(geofile_names, options)
        publish_geoserver_files(geofile_names[:public], options[:geoserver_url], true)
        publish_geoserver_files(geofile_names[:ucb], options[:geoserver_secure_url], false)
      end

      def get_reference_urls(options)
        {}.tap do |refs|
          if options[:update_reference_field]
            Config.reference_urls.each_key do |key|
              refs[key] = reference_url(key, options)
            end
          end
        end
      end

      def root_path
        File.expand_path('..', __dir__)
      end

      private

      def publish_geoserver_files(files, url, is_public)
        return if files.empty?

        url ||= if is_public
                  ENV.fetch('GEOSERVER_URL',
                            Config.default_options[:geoserver_url])
                else
                  ENV.fetch('GEOSERVER_SECURE_URL',
                            Config.default_options[:geoserver_secure_url])
                end
        publisher = GeoserverPublisher.new(url)
        publisher.batch_update(files)
      end

      def geo_url(url)
        uri = URI(url)
        uri_port = uri.port.to_s
        port = uri_port.start_with?('80') ? ":#{uri_port}" : ''
        "#{uri.scheme}://#{uri.host}#{port}"
      end

      def add_trailing_slash(url)
        original_uri = URI.parse(url)
        original_uri.path += '/' unless original_uri.path.end_with?('/')
        original_uri
      end

      def reference_url(key, options)
        default_option_value = Config.default_options[key]
        new_url = options[key] || ENV.fetch(key.to_s.upcase, default_option_value)
        new_url = geo_url(new_url) if %w[geoserver_url geoserver_secure_url].include?(key.to_s)
        add_trailing_slash(new_url).to_s
      end

    end
  end
end
