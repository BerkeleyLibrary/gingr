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

      def reference_url(key, options)
        prepare_url options[key] || Gingr::Config.getopt(key)
      end

      def prepare_url(url)
        URI.parse(url).tap do |uri|
          uri.user = nil
          uri.password = nil
          uri.path << '/' unless uri.path.end_with? '/'
          uri.path.chomp! 'rest/'
        end.to_s
      end
    end
  end
end
