# frozen_string_literal: true
require 'fileutils'
require 'pathname'
require 'zip'
require_relative 'config'
require_relative 'logging'

module Gingr
  module DataHandler
    include Config
    include Logging

    @spatial_root = ''
    @geoserver_root = ''
    @processing_root = ''

    class << self
      include Logging

      attr_accessor :spatial_root, :geoserver_root, :processing_root

      def extract_and_move(zip_file)
        extract_to_path = perform_extraction(zip_file)
        geofile_ingestion_path = organize_files_for_ingestion(extract_to_path)
        geofile_name_hash = geofile_access_hash(geofile_ingestion_path)
        { extract_to_path:, geofile_name_hash: }
      end

      private

      def perform_extraction(zip_file)
        extract_to_path = directory_path(zip_file)
        puts extract_to_path
        clr_directory(extract_to_path)
        extract_zipfile(zip_file)
        extract_to_path
      end

      def organize_files_for_ingestion(extract_to_path)
        geofile_ingestion_path = File.join(extract_to_path, Config.geofile_ingestion_dirname)
        move_files_to_ingestion_path(geofile_ingestion_path)
        geofile_ingestion_path
      end

      def extract_zipfile(zip_file, to_dir = @processing_root)
        Zip::File.open(zip_file) do |zip|
          zip.each do |entry|
            entry.extract(destination_directory: to_dir) { true }
          end
        end
      rescue StandardError => e
        logger.error "An unexpected error occurred during unzip #{zip_file}: #{e.message}"
        raise
      end

      def move_files_to_ingestion_path(geofile_ingestion_path)
        subdirectory_list(geofile_ingestion_path).each do |subdirectory_path|
          move_a_record(subdirectory_path)
        end
      rescue StandardError => e
        logger.error "An unexpected error occurred while moving geofiles to #{geofile_ingestion_path}: #{e.message}"
      end

      def move_a_record(dir_path)
        subfile_list(dir_path).each do |file|
          if File.basename(file) == 'map.zip'
            dest_dir_path = file_path(dir_path, @geoserver_root)
            unzip_map_files(dest_dir_path, file)
          else
            dest_dir_path = file_path(dir_path, @spatial_root)
            mv_spatial_file(dest_dir_path, file)
          end
        end
      end

      def directory_path(zip_file)
        subdir_name = File.basename(zip_file, '.*')
        File.join(@processing_root, subdir_name)
      end

      def clr_directory(directory_name)
        FileUtils.rm_r(directory_name) if File.directory? directory_name
      rescue Errno::EACCES
        logger.error("Permission denied to clear #{directory_name}")
        raise
      end

      def subdirectory_list(directory_path)
        Pathname(directory_path).children.select(&:directory?)
      end

      def subfile_list(directory_path)
        Pathname(directory_path).children.select(&:file?)
      end

      def geofile_access_hash(directory_path)
        public_names = []
        ucb_names = []
        subdirectory_list(directory_path).each do |sub_dir|
          hash = name_access_hash(sub_dir)
          hash[:public_access] ? public_names << hash[:name] : ucb_names << hash[:name]
        end
        { public: public_names, ucb: ucb_names }
      end

      def access_type(dir)
        json_hash = geoblacklight_hash(dir)
        value = json_hash['dct_accessRights_s'].downcase
        value == 'public' ? 'public' : 'UCB'
      end

      def geoblacklight_hash(dir)
        json_filepath = File.join(dir, 'geoblacklight.json')
        json_data = File.read(json_filepath)
        JSON.parse(json_data)
      end
      
      def name_access_hash(dir)
        basename = File.basename(dir).split('_').last
        json_hash = geoblacklight_hash(dir)
        format = json_hash['dct_format_s'].downcase
        ext = format == 'shapefile' ? '.shp' : '.tif'
        access_right = json_hash['dct_accessRights_s'].downcase
        { name: "#{basename}#{ext}", public_access: access_right == 'public' }
      end

      def unzip_map_files(dest_dir, map_zipfile)
        FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
        extract_zipfile(map_zipfile, dest_dir)
      end

      def mv_spatial_file(dest_dir, file)
        FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
        to_file = File.join(dest_dir, File.basename(file))
        FileUtils.cp(file, to_file)
      end

      def file_path(dir_path, root)
        #  geofiles/spatial/{UCB,public}/berkeley-{arkID}
        arkid = File.basename(dir_path).strip
        type = access_type(dir_path)
        File.join(root, type, "berkeley-#{arkid}")
      end
    end
  end
end
