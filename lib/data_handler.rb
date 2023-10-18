# frozen_string_literal: true

require 'zip'
require 'pathname'
require_relative 'config'

# Ginger module
module Gingr
  # handle ingestion data
  module DataHandler
    include Gingr::Config

    @spatial_root = ''
    @geoserver_root = ''

    class << self
      attr_accessor :spatial_root, :geoserver_root

      def extract_move(zip_file, to_dir_path)
        extract_path = make_dir(to_dir_path, File.basename(zip_file, '.*'))
        extract_zipfile(zip_file, extract_path)

        geofile_ingestion_dir_path = move_files(extract_path)
        { jsonfile_dir_list: extract_path, geofile_name_hash: get_geofile_name_hash(geofile_ingestion_dir_path) }
      end

      # workflow to be discuss: need to remove the extract_path before extract zipfile?
      def extract_zipfile(zip_file, extraction_path)
        Dir.mkdir(extraction_path) unless File.directory? extraction_path
        Zip::File.open(zip_file) do |zip|
          zip.each do |entry|
            entry_path = File.join(extraction_path, entry.name)
            entry.extract(entry_path) { true }
          end
        end
      end

      def move_files(from_dir_path)
        geofile_ingestion_dir_path = File.join(from_dir_path, Config.geofile_ingestion_dirname)
        subdirectory_list(geofile_ingestion_dir_path).each do |subdirectory|
          move_ingestion_files(subdirectory)
        end
        geofile_ingestion_dir_path
      end

      # move ingestion files from a structured ingestion zip file
      def move_ingestion_files(dir)
        subfile_list(dir).each do |file|
          if File.basename(file) == 'map.zip'
            dest_dir = file_path(dir, @geoserver_root)
            unzip_map_files(dest_dir, file)
          else
            dest_dir = file_path(dir, @spatial_root)
            mv_spatial_file(dest_dir, file)
          end
        end
      end

      def make_dir(dir_path, subdir_name)
        subdir_path = File.join(dir_path, subdir_name)
        Dir.mkdir(subdir_path) unless File.directory? subdir_path
        subdir_path
      end

      def subdirectory_list(directory_path)
        Pathname(directory_path).children.select(&:directory?)
      end

      def subfile_list(directory_path)
        Pathname(directory_path).children.select(&:file?)
      end

      def get_geofile_name_hash(directory_path)
        public_names = []
        ucb_names = []
        subdirectory_list(directory_path).each do |sub_dir|
          access = access_type(sub_dir)
          name = geofile_basename(sub_dir)
          access == 'public' ? public_names << name : ucb_names << name
        end
        { public: public_dirs, ucb: ucb_dirs }
      end

      def access_type(dir)
        value = field_value(dir, 'dct_accessRights_s').downcase
        # value = 'Public' # fake data
        value == 'public' ? 'public' : 'ucb'
      end

      private

      def geofile_basename(dir)
        basename = File.basename(dir)
        value = field_value(dir, 'dct_format_s').downcase
        ext = value == 'shapefile' ? '.shp' : '.tiff'
        "#{basename}#{ext}"
      end

      def field_value(dir, field_name)
        json_filepath = File.join(dir, 'geoblacklight.json')
        json_data = File.read(json_filepath)
        data_hash = JSON.parse(json_data)
        data_hash[field_name]
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

      def file_path(dir, root)
        #  /srv/geofiles/spatial/{UCB,public}/berkeley-{arkID}/data.zip
        arkid = dir.to_s.split('/')[-1].strip
        type = access_type(dir)
        File.join(root, type, "berkeley-#{arkid}")
      end
    end
  end
end
