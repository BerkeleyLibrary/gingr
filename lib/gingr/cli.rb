# frozen_string_literal: true
require 'thor'
require_relative 'config'
require_relative 'import_util'

module Gingr
  class Cli < Thor
    include Config
    include ImportUtil

    Thor.check_unknown_options!

    desc 'solr',
         'Giving a directory path, it will index all json files from the directory/sub-directory to solr'
    long_desc <<-TEXT, wrapping: false
          examples:\n
          1) ruby bin/import solr tmp/test_public \n
          2) ruby bin/import solr tmp/test_public  --no-update_reference_field \n
            (it will update reference urls from 'dct_references_s' field in each geoblacklight json file \n
            with current download_url, geoserver_url, geoserver_secure_url)
    TEXT
    option :download_url
    option :geoserver_url
    option :geoserver_secure_url
    option :update_reference_field, type: :boolean, default: false
    option :solr_url
    def solr(dir_path)
      reference_urls = ImportUtil.get_reference_urls(options)
      solr_url = options[:solr_url] || ENV.fetch('SOLR_URL', nil)
      ImportUtil.index_solr_from_dir(dir_path, solr_url, reference_urls)
      txt = "all json files under '#{dir_path}' and subdirectories have been indexed to solr #{solr_url} successfully"
      Config.logger.info(txt)
    end

    desc 'geoserver', 'publish a giving shapefile or GeoTIFF file to a geoserver'
    long_desc <<-TEXT, wrapping: false
         examples: \n
         1) ruby bin/import geoserver fk4cr7f93g.shp \n
         2) ruby bin/import geoserver fk4h14n50v.shp  --no-is-public
    TEXT
    option :geoserver_url
    option :is_public, type: :boolean, default: true
    def geoserver(filename)
      url = options[:geoserver_url]
      url ||= options[:is_public] ? ENV.fetch('GEOSERVER_URL', nil) : ENV.fetch('GEOSERVER_SECURE_URL', nil)
      publisher = GeoserverPublisher.new(url)
      publisher.update(filename)
      Config.logger.info("'#{filename}' - published to geoserver #{url} successfully")
    end

    desc 'unpack',
         'unpack a giving zip file, move shapefiles and GeoTIFF files to geoserver_root, other files to spatial_root'
    long_desc <<-TEXT, wrapping: false
         * When giving a zip file without path, it will look for a zip file under /app/import/
    TEXT
    option :spatial_root
    option :geoserver_root
    def unpack(zipfile)
      zipfile_path = zipfile == File.basename(zipfile) ? File.join(ImportUtil.root_path, 'import', zipfile) : zipfile
      DataHandler.spatial_root = options[:spatial_root] || ENV.fetch('SPATIAL_ROOT', nil)
      DataHandler.geoserver_root = options[:geoserver_root] || ENV.fetch('GEOSERVER_ROOT', nil)

      temp_path = File.join(Dir.pwd, 'tmp')
      DataHandler.extract_and_move(zipfile_path, temp_path)
    end

    desc 'all',
         'unpack a giving zip file, move files, index json files to solr and publish geofiles to geoservers'
    long_desc <<-TEXT, wrapping: false
          1) move all geofiles to geoserver_root \n
          2) move all data.zip, ISO19139.xml and document files to spatial_root \n
          2) index all geoblacklight json files to solr \n
          3) publish all shapefiles and GeoTIFF files to geoserver \n
    TEXT
    option :solr_url
    option :update_reference_field, type: :boolean, default: false
    option :spatial_root
    option :geoserver_root
    option :geoserver_url
    option :geoserver_secure_url
    def all(zipfile)
      unpacked = unpack(zipfile)
      solr(unpacked[:extract_to_path])

      geofile_names = unpacked[:geofile_name_hash]
      ImportUtil.publish_geoservers(geofile_names, options)
      Config.logger.info("#{zipfile} - all imported")
    end

    desc 'geoserver_workspace', 'create a workspace in a geoserver'
    long_desc <<-LONGDESC
         This is for spec test. Geodata website only needs one workspace "UCB"
    LONGDESC
    option :geoserver_url
    option :is_public, type: :boolean, default: true
    def geoserver_workspace(name)
      url = options[:geoserver_url]
      url ||= options[:is_public] ? ENV.fetch('GEOSERVER_URL', nil) : ENV.fetch('GEOSERVER_SECURE_URL', nil)
      publisher = GeoserverPublisher.new(url)
      publisher.create_workspace(name)
      Config.logger.info("geoserver workspace '#{name}' - created successfully")
    end

    def self.exit_on_failure?
      true
    end
  end
end