# frozen_string_literal: true

require_relative 'publish'
require 'uri'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config
  # publish services to geoserver
  class GeoserverPublisher
    def initialize(url)
      uri = URI(url)
      @conn = Geoserver::Publish::Connection.new({ 'url' => rest_url(uri), 'user' => uri.user,
                                                   'password' => uri.password.to_s })
    end

    def update(filename)
      name = File.basename(filename, '.*')
      filepath = "file:///srv/geofiles/berkeley-#{name}/#{filename}"
      File.extname(filename).downcase == '.shp' ? publish_shapefile(filepath, name) : pulsih_geotiff(filepath, name)
    rescue Geoserver::Publish::Error
      Config.logger.error("Publish Geoserver error: #{filename}")
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

    def publish(filename); end

    def rest_url(uri)
      port = uri.port == 8080 ? ':8080' : ''
      "#{uri.scheme}://#{uri.host}#{port}#{uri.path}"
    end
  end
end
