# frozen_string_literal: true

# require 'geoserver/publish'
# require 'geoserver/publish/workspace'
require_relative 'publish'
require 'uri'
require_relative 'config'

# Ginger module
module Gingr
  include Gingr::Config
  # publish service to geoserver
  class GeoserverPublisher
    def initialize(url)
      uri = URI(url)
      @conn = Geoserver::Publish::Connection.new({ 'url' => rest_url(uri), 'user' => uri.user,
                                                   'password' => uri.password.to_s })
    end

    def update(filename)
      name = File.basename(filename, '.*')
      filepath = "file:///srv/geofiles/berkeley-#{name}/#{filename}"

      ext = File.extname(filename).downcase
      if ext == '.shp'

        Geoserver::Publish.shapefile(connection: @conn, workspace_name: 'UCB', file_path: filepath,
                                     id: name, title: name)
      elsif ext == '.tiff'
        Geoserver::Publish.geotiff(connection: @conn, workspace_name: 'UCB', file_path: filepath, id: name,
                                   title: name)
      end
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
      port = uri.port == 8080 ? ':8080' : ''
      "#{uri.scheme}://#{uri.host}#{port}#{uri.path}"
    end
  end
end
