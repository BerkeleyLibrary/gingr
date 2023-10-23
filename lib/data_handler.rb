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

      def extract_and_move(zip_file, to_dir_path)
        extract_to_path = make_dir(to_dir_path, File.basename(zip_file, '.*'))
        extract_zipfile(zip_file, extract_to_path)

        geofile_ingestion_dir_path = move_files(extract_to_path)
        { extract_to_path:, geofile_name_hash: get_geofile_name_hash(geofile_ingestion_dir_path) }
      end

      # workflow to be discuss: need to remove the extract_to_path before extract zipfile?
      def extract_zipfile(zip_file, extract_to_path)
        Dir.mkdir(extract_to_path) unless File.directory? extract_to_path
        Zip::File.open(zip_file) do |zip|
          zip.each do |entry|
            entry_path = File.join(extract_to_path, entry.name)
            entry.extract(entry_path) { true }
          end
        end
      end

      def move_files(from_dir_path)
        geofile_ingestion_dir_path = File.join(from_dir_path, Config.geofile_ingestion_dirname)
        subdirectory_list(geofile_ingestion_dir_path).each do |subdirectory_path|
          move_ingestion_files(subdirectory_path)
        end
        geofile_ingestion_dir_path
      end

      # move ingestion files from a structured ingestion zip file
      def move_ingestion_files(dir_path)
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
          hash = name_access_hash(sub_dir)
          hash[:public_access] ? public_names << hash[:name] : ucb_names << hash[:name]
        end
        { public: public_names, ucb: ucb_names }
      end

      def access_type(dir)
        data_hash = geoblacklight_hash(dir)
        value = data_hash['dct_accessRights_s'].downcase
        value == 'public' ? 'public' : 'UCB'
      end

      private

      def geoblacklight_hash(dir)
        json_filepath = File.join(dir, 'geoblacklight.json')
        json_data = File.read(json_filepath)
        JSON.parse(json_data)
      end

      def name_access_hash(dir)
        basename = File.basename(dir).split('_').last
        data_hash = geoblacklight_hash(dir)
        format = data_hash['dct_format_s'].downcase
        ext = format == 'shapefile' ? '.shp' : '.tiff'
        right = data_hash['dct_accessRights_s'].downcase
        { name: "#{basename}#{ext}", public_access: right == 'public' }
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
