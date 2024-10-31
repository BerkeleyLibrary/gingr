# frozen_string_literal: true

require 'thor'
require_relative 'import_util'
require_relative 'config'
require_relative 'watcher'

module Gingr
  class Cli < Thor
    include Config
    include ImportUtil
    include Logging

    Thor.check_unknown_options!

    class << self
      def exit_on_failure?
        true
      end
    end

    desc 'watch', 'Watches a Gingr directory for files ready to be processed'
    long_desc <<-TEXT, wrapping: false
    EXAMPLES
      gingr watch data/gingr --solr-url=https://foo:bar@solr.lib.berkeley.edu:8983/solr/geodata ...
    TEXT
    option :solr_url
    option :update_reference_field, type: :boolean, default: true
    option :spatial_root
    option :spatial_url
    option :geoserver_root
    option :geoserver_url
    option :geoserver_secure_url
    def watch(root_dir = nil)
      watcher = Gingr::Watcher.new(root_dir, options)
      watcher.start!
    end

    desc 'solr',
         'Giving a directory path, it will index all json files from the directory/sub-directory to solr'
    long_desc <<-TEXT, wrapping: false
          examples:\n
          1) ruby bin/import solr tmp/test_public \n
          2) ruby bin/import solr tmp/test_public  --update-reference-field \n
            (it will update reference urls from 'dct_references_s' field in each geoblacklight json file \n
            with current spatial_url, geoserver_url, geoserver_secure_url)
    TEXT
    option :spatial_url
    option :geoserver_url
    option :geoserver_secure_url
    option :update_reference_field, type: :boolean, default: true
    option :solr_url
    def solr(directory)
      reference_urls = ImportUtil.get_reference_urls(options)
      solr = Gingr::SolrIndexer.new(options[:solr_url], reference_urls)
      solr.index_directory(directory)
    end

    desc 'geoserver', 'publish a given shapefile or GeoTIFF file to a geoserver'
    long_desc <<-TEXT, wrapping: false
         examples: \n
         1) ruby bin/import geoserver fk4cr7f93g.shp \n
         2) ruby bin/import geoserver fk4h14n50v.shp  --no-is-public
    TEXT
    option :geoserver_url
    option :is_public, type: :boolean, default: true
    def geoserver(filename)
      url = options[:geoserver_url]
      default = options[:is_public] ? :geoserver_url : :geoserver_secure_url
      publisher = GeoserverPublisher.new(url, default:)
      publisher.publish(filename)
    end

    desc 'unpack',
         'unpack a given zip file, move shapefiles and GeoTIFF files to geoserver_root, other files to spatial_root'
    long_desc <<-TEXT, wrapping: false
         * When giving a zip file without path, it will look for a zip file under /app/import/
    TEXT
    option :spatial_root
    option :geoserver_root
    def unpack(zipfile)
      zipfile_path = zipfile == File.basename(zipfile) ? File.join(ImportUtil.root_path, 'import', zipfile) : zipfile
      set_data_handler(options[:spatial_root], options[:geoserver_root])
      DataHandler.extract_and_move(zipfile_path)
    end

    desc 'all',
         'unpack a given zip file, move files, index json files to solr and publish geofiles to geoservers'
    long_desc <<-TEXT, wrapping: false
          1) move all geofiles to geoserver_root \n
          2) move all data.zip, ISO19139.xml and document files to spatial_root \n
          2) index all geoblacklight json files to solr \n
          3) publish all shapefiles and GeoTIFF files to geoserver \n
    TEXT
    option :solr_url
    option :update_reference_field, type: :boolean, default: false
    option :spatial_root
    option :spatial_url
    option :geoserver_root
    option :geoserver_url
    option :geoserver_secure_url
    def all(zipfile)
      unpacked = unpack(zipfile)
      total_indexed = solr(unpacked[:extract_to_path])

      geofile_names = unpacked[:geofile_name_hash]
      geoserver_urls = options.slice(:geoserver_url, :geoserver_secure_url).transform_keys(&:to_sym)
      failed_files = Gingr::GeoserverPublisher.publish_inventory(geofile_names, **geoserver_urls)

      report(total_indexed, failed_files, zipfile)
      # logger.info("Total ingested records: #{total_indexed}")
      # logger.error("#{failed_files.join(';')} failed published to geoservers.") unless failed_files.empty?
      # logger.info("#{zipfile} - all imported")
    end

    desc 'geoserver_workspace', 'create a workspace in a geoserver'
    long_desc <<-LONGDESC
         This is for spec test. Geodata website only needs one workspace "UCB"
    LONGDESC
    option :geoserver_url
    option :is_public, type: :boolean, default: true
    def geoserver_workspace(workspace_name = nil)
      default = options[:is_public] ? :geoserver_url : :geoserver_secure_url
      publisher = GeoserverPublisher.new(options[:geoserver_url], default:, workspace_name:)
      publisher.create_workspace
    end

    private

    def set_data_handler(spatial_root, goserver_root)
      DataHandler.spatial_root = spatial_root || ENV.fetch('SPATIAL_ROOT',
                                                           Config.default_options[:spatial_root])
      DataHandler.geoserver_root = goserver_root || ENV.fetch('GEOSERVER_ROOT',
                                                              Config.default_options[:geoserver_root])
      gingr_watch_root_dir ||= ENV['GINGR_WATCH_DIRECTORY'] || '/opt/app/data/gingr'
      DataHandler.processing_root = File.join(gingr_watch_root_dir, 'processing')
    end

    def report(total_indexed, failed_files, zipfile)
      if total_indexed.nil?
        logger.error('Solr indexing failed')
        logger.info("#{zipfile} - not imported")
        return
      end
      logger.info("#{zipfile} - all imported, total records: #{total_indexed}")
      return if failed_files.empty?

      logger.warn("#{zipfile} - some shapefile or GeoTIFF files not published to Geoservers")
      logger.error("Failed to published geo files: #{failed_files.join('; ')}")
    end
  end
end
