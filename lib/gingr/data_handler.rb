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
        summary = prepare_publishing_files(extract_to_path)
        geofile_name_hash = analyze_summary(summary)
        { extract_to_path:, geofile_name_hash: }
      end

      private

      def analyze_summary(summary)
        public_map_files = []
        ucb_map_files = []
        summary.each do |summ|
          filename = summ[:map_filename]
          summ[:public_access] ? public_map_files << filename : ucb_map_files << filename
        end
        { public_files: public_map_files.compact.reject(&:empty?), ucb_files: ucb_map_files.compact.reject(&:empty?) }
      end

      # Extacting ingestion zip file to processing directory
      def perform_extraction(zip_file)
        extract_to_path = prepare_extract_to_path(zip_file)
        extract_zipfile(zip_file)
        extract_to_path
      end

      def prepare_extract_to_path(zip_file)
        dir_name = File.basename(zip_file, '.*')
        extract_to_path = File.join(@processing_root, dir_name)
        clr_directory(extract_to_path)
        extract_to_path
      end

      # Moving files to Geoserver and spatial server
      def prepare_publishing_files(extract_to_path)
        from_geofile_ingestion_path = File.join(extract_to_path, Config.geofile_ingestion_dirname)
        subdirectory_list(from_geofile_ingestion_path).map { |dir| move_a_record(dir) }
      rescue StandardError => e
        logger.error "An error occurred while extracting and moving files from #{from_geofile_ingestion_path}: #{e.message}"
      end
     
      def extract_zipfile(zip_file, to_dir: @processing_root, is_flatten: false)
        Zip::File.open(zip_file) do |zip|
          zip.each do |entry|
            next if entry.directory? && is_flatten

            entry.name = File.basename(entry.name) if is_flatten
            entry.extract(destination_directory: to_dir) { true }
          end
        end
      rescue StandardError => e
        logger.error "An unexpected error occurred during unzip #{zip_file}: #{e.message}"
        raise
      end
      # some records may not have data.zip or map.zip files
      def move_a_record(dir_path)
        attributes = record_info(dir_path)
        arkid = File.basename(dir_path).strip
        map_filename = nil
        souredata_moved = false

        subfile_list(dir_path).each do |file|
          filename = File.basename(file)
          if filename == 'map.zip'
            map_filename = move_map_file(file, arkid, attributes) 
          else
            souredata_moved = move_source_file(file, arkid, attributes[:public_access])
          end
        end
        logger.warning " '#{arkid} has no map.zip file, please check" if map_filename.nil?
        logger.warning " '#{arkid} has no data.zip file, please check" unless souredata_moved
        { public_access: attributes[:public_access], map_filename: }
      end

      def move_map_file(file, arkid, attributes)
        dirname = attributes[:public_access] ? 'public' : 'UCB'
        dest_dir_path = file_path(@geoserver_root, arkid, dirname)
        unzip_map_files(dest_dir_path, file)
        format = attributes[:format].downcase
        ext = format == 'shapefile' ? '.shp' : '.tif'
        "#{arkid}#{ext}"
      rescue StandardError => e
        logger.error "Failed to move map file '#{file}' for arkid '#{arkid}': #{e.message}"
        ''
      end

      def move_source_file(file, arkid, public_access)
        dirname = source_dest_dirname(file, public_access)
        dest_dir_path = file_path(@spatial_root, arkid, dirname)
        mv_spatial_file(dest_dir_path, file)
        true
      rescue StandardError => e
        logger.error "Failed to move soucedata '#{file}' for '#{arkid}': #{e.message}"
      end

      def source_dest_dirname(file, public_access)
        return 'public' if public_access
        
        filename = File.basename(file)
        return 'metadata' unless %w[data.zip map.zip geoblacklight.json].include?(filename)
        
        'UCB'
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

      def record_info(dir)
        json_filepath = File.join(dir, 'geoblacklight.json')
        json_data = File.read(json_filepath)
        json_hash = JSON.parse(json_data)
        public_access = json_hash['dct_accessRights_s'].downcase == 'public'
        format = json_hash['dct_format_s'].downcase
        { public_access:, format: }
      end

      def unzip_map_files(dest_dir, map_zipfile)
        FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
        extract_zipfile(map_zipfile, to_dir:dest_dir, is_flatten:true)
      end

      def mv_spatial_file(dest_dir, file)
        FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
        to_file = File.join(dest_dir, File.basename(file))
        FileUtils.cp(file, to_file)
      end

      def file_path(root, arkid, dirname)
        File.join(root, dirname, "berkeley-#{arkid}")
      end

    end
  end
end