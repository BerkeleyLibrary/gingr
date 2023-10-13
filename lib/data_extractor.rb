# frozen_string_literal: true
require 'geoserver/publish'
require 'uri'

# Ginger module
module Gingr
    include Gingr::Config

    # extract zip file and move to specific location
    class DataExtractor
        @spatial_root = ''
        @geoserver_root = ''

        class << self:
            attr_accessor :spatial_root, :geoserver_root
        end

        def unzip(zipfile_path, to_path)
            Zip::File.open(zipfile_path) do |zipfile|
              zipfile.each do |file|
                to_filepath = File.join(to_path, file.name)
                FileUtils.mkdir_p(File.dirname(to_filepath))
                zipfile.extract(file, to_filepath) { true }
              end
            end
          end
        end

        def move_files(dir):
            files = Dir.glob(dir).select { |file| File.file?(file) }
            files.each do |file|
              if File.extname(file) == 'map.zip'
                dest_dir = file_path(dir, @geoserver_root)
                FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
                self.unzip(file, dest_dir)
              else
                dest_dir = file_path(dir, @spatial_root)
                FileUtils.mkdir_p(dest_dir) unless File.directory? dest_dir
                to_file = File.join(dest_dir, File.basename(file))
                FileUtils.cp(file, to_file)
              end
            end
          end
         
          def file_path(dir, root)
            #  /srv/geofiles/{UCB,public}/berkeley-{arkID}/data.zip
            arkid = dir.to_s.split('/')[-1].strip()
            type = access_type(dir)
            File.join(root, type, "berkeley-#{arkid}")
          end
      
          def access_type(dir):
              json_filepath = File.join(dir, 'geoblacklight.json')
              json_data = File.read(json_filepath)
              data_hash = JSON.parse(json_data)
              data_hash['dct_accessRights_s'].downcase == 'public' ? 'public' : 'UCB'
          end
        
    end
      