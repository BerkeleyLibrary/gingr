# frozen_string_literal: true

require 'geoserver/publish'
require 'uri'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config
  # publish service to geoserver
  class GeoserverPublisher
    @geoserver_root = ''
    @access = ''

    class << self
      attr_accessor :geoserver_root, :access
    end

    def initialize(url)
      uri = URI(url)
      @conn = Geoserver::Publish::Connection.new({ 'url' => "#{uri.host}#{uri.path}", 'user' => uri.user,
                                                   'password' => uri.password.to_s })
    end

    def update(filename)
      name = File.basename(filename, '.*')
      filepath = file_path(name, filename)

      ext = File.extname(filename).downcase
      if ext == '.shp'
        Geoserver::Publish.shapefile(connection: @conn, workspace_name: 'UCB', file_path: filepath, id: name,
                                     title: name)
      elsif ext == '.tiff'
        Geoserver::Publish.geotiff(connection: @conn, workspace_name: 'UCB', file_path: filepath, id: name,
                                   title: name)
      end
    end

    def file_path(name, filename)
      # "file:///srv/geofiles/#{@access}/berkeley-#{name}/#{filename}"
      "#{@geoserver_root}/#{@access}/berkeley-#{name}/#{filename}"
    end
  end
end
