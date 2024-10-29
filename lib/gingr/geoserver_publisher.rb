# frozen_string_literal: true
require 'geoserver/publish'
require 'uri'
require_relative 'config'
require_relative 'logging'

module Gingr
  class GeoserverPublisher
    include Logging

    DEFAULT_REMOTE_ROOT = '/srv/geofiles'
    DEFAULT_WORKSPACE = 'UCB'

    attr_reader :connection, :remote_root, :workspace_name
    
    # attr_reader :remote_root
    # attr_reader :workspace_name

    class << self
      def publish_inventory(inventory, geoserver_url: nil, geoserver_secure_url: nil)
        if !inventory[:public].empty?
          public_publisher = new(geoserver_url)
          public_publisher.batch_publish(inventory[:public])
        end

        if !inventory[:ucb].empty?
          secure_publisher = new(geoserver_secure_url, default: :geoserver_secure_url)
          secure_publisher.batch_publish(inventory[:ucb])
        end
      end

      def parse_connection_string(geoserver_baseurl)
        uri = URI.parse(geoserver_baseurl)
        uri.path << '/' unless uri.path.end_with? '/'
        uri.path << 'rest/' unless uri.path.end_with? 'rest/'

        return URI::Generic.build(
          scheme: uri.scheme,
          host: uri.host,
          port: uri.port == uri.default_port ? nil : uri.port,
          path: uri.path,
          fragment: uri.fragment,
          query: uri.query,
        ).to_s, uri.user, uri.password
      end
    end

    def initialize(conn = nil, default: nil, remote_root: nil, workspace_name: nil)
      conn ||= Gingr::Config.getopt(default || :geoserver_url)

      # Coerce a connection string into an actual connection object
      if conn.kind_of? String
        rest_url, user, password = self.class.parse_connection_string(conn)
        conn = Geoserver::Publish::Connection.new({
          'url' => rest_url,
          'user' => user,
          'password' => password,
        })
      end

      @connection = conn
      @remote_root = (remote_root || DEFAULT_REMOTE_ROOT).chomp '/'
      @workspace_name = workspace_name || DEFAULT_WORKSPACE
    end

    def batch_publish(filenames)
      filenames.each(&method(:publish))
    end

    def publish(filename)
      id = File.basename(filename, '.*')
      file_path = remote_filepath(id, filename)
      if File.extname(filename).casecmp?('.shp')
        publish_shapefile(file_path, id)
      else
        publish_geotiff(file_path, id)
      end
    end

    def create_workspace
      logger.info("Creating workspace #{workspace_name} in #{geoserver_url}")

      workspace = Geoserver::Publish::Workspace.new(connection)
      if workspace.find(workspace_name:)
        logger.debug("Workspace #{workspace_name} already exists")
      else
        workspace.create(workspace_name:)
      end
    end

    private

    def publish_shapefile(file_path, id)
      logger.debug("Publishing shapefile #{id} to #{geoserver_url}")
      Geoserver::Publish.shapefile(connection:, workspace_name:, file_path:, id:, title: id)
    end

    def publish_geotiff(file_path, id)
      logger.debug("Publishing geotiff #{id} to #{geoserver_url}")
      Geoserver::Publish.geotiff(connection:, workspace_name:, file_path:, id:, title: id)
    end

    def remote_filepath(id, filename)
      "file://#{remote_root}/berkeley-#{id}/#{filename}"
    end

    def geoserver_url
      connection.config['url']
    end
  end
end
