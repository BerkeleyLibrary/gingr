# frozen_string_literal: true

require 'zip'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config

  # extract zip file and move to specific location
  class DataTansferHandler
    @spatial_root = ''
    @geoserver_root = ''

    class << self
      attr_accessor :spatial_root, :geoserver_root
    end

    def extract_zipfile(zip_file, extraction_path)
      Dir.mkdir(extraction_path) unless File.directory? extraction_path
      Zip::File.open(zip_file) do |zip|
        zip.each do |entry|
          entry_path = File.join(extraction_path, entry.name)
          entry.extract(entry_path)
        end
      end
    end

    # move ingestion files from a structured ingestion zip file
    def move_ingestion_files(dir)
      files = Dir.glob(dir).select { |file| File.file?(file) }
      files.each do |file|
        if File.extname(file) == 'map.zip'
          dest_dir = file_path(dir, @geoserver_root)
          unzip_map_files(dest_dir, file)
        else
          dest_dir = file_path(dir, @spatial_root)
          mv_spatial_file(dest_dir, file)
        end
      end
    end

    def unzip_map_files(dest_dir, map_zipfile)
      FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
      unzip(map_zipfile, dest_dir)
    end

    def mv_spatial_file(dest_dir, file)
      FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
      to_file = File.join(dest_dir, File.basename(file))
      FileUtils.cp(file, to_file)
    end
    # def move_ingestion_files(dir)
    #   files = Dir.glob(dir).select { |file| File.file?(file) }
    #   files.each do |file|
    #     if File.extname(file) == 'map.zip'
    #       dest_dir = file_path(dir, @geoserver_root)
    #       FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
    #       unzip(file, dest_dir)
    #     else
    #       dest_dir = file_path(dir, @spatial_root)
    #       FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
    #       to_file = File.join(dest_dir, File.basename(file))
    #       FileUtils.cp(file, to_file)
    #     end
    #   end
    # end

    def file_path(dir, root)
      #  /srv/geofiles/{UCB,public}/berkeley-{arkID}/data.zip
      arkid = dir.to_s.split('/')[-1].strip
      type = access_type(dir)
      File.join(root, type, "berkeley-#{arkid}")
    end

    def access_type(dir)
      json_filepath = File.join(dir, 'geoblacklight.json')
      json_data = File.read(json_filepath)
      data_hash = JSON.parse(json_data)
      data_hash['dct_accessRights_s'].downcase == 'public' ? 'public' : 'UCB'
    end
  end
end
