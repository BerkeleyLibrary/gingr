# frozen_string_literal: true
require 'geoserver/publish'
require 'uri'
require_relative 'logging'

module Gingr
  class GeoserverPublisher
    include Logging

    def initialize(url)
      uri = URI(url)
      @conn = Geoserver::Publish::Connection.new({
        'url' => rest_url(uri),
        'user' => uri.user,
        'password' => uri.password.to_s,
      })
    end

    def update(filename)
      name = File.basename(filename, '.*')
      filepath = "file:///srv/geofiles/berkeley-#{name}/#{filename}"
      File.extname(filename).downcase == '.shp' ? publish_shapefile(filepath, name) : pulsih_geotiff(filepath, name)
    rescue Geoserver::Publish::Error => e
      logger.error("Publish Geoserver error: #{filename} -- #{e.inspect}")
      raise
    end

    def publish_shapefile(filepath, name)
      Geoserver::Publish.shapefile(connection: @conn, workspace_name: 'UCB', file_path: filepath,
                                   id: name, title: name)
    end

    def pulsih_geotiff(filepath, name)
      Geoserver::Publish.geotiff(connection: @conn, workspace_name: 'UCB', file_path: filepath, id: name,
                                 title: name)
    end

    def batch_update(filename_list)
      filename_list.each { |filename| update(filename) }
    end

    def create_workspace(name)
      workspace = Geoserver::Publish::Workspace.new(@conn)
      workspace.create(workspace_name: name)
    end

    private

    def rest_url(uri)
      uri_port = uri.port.to_s
      port = uri_port.start_with?('80') ? ":#{uri_port}" : ''
      "#{uri.scheme}://#{uri.host}#{port}#{uri.path}"
    end
  end
end
