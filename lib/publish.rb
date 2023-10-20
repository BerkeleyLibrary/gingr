# frozen_string_literal: true

require 'erb'
require 'faraday'
require 'json'
require 'yaml'

module Geoserver
  # from geoserver-publish gem: get a specific store name
  module Publish
    require 'geoserver/publish/config'
    require 'geoserver/publish/connection'
    require 'geoserver/publish/coverage'
    require 'geoserver/publish/coverage_store'
    require 'geoserver/publish/create'
    require 'geoserver/publish/data_store'
    require 'geoserver/publish/feature_type'
    require 'geoserver/publish/geowebcache'
    require 'geoserver/publish/layer'
    require 'geoserver/publish/style'
    require 'geoserver/publish/version'
    require 'geoserver/publish/workspace'

    def self.delete_geotiff(workspace_name:, id:, connection: nil)
      coverage_store_name = "berkeley_#{id}"
      CoverageStore.new(connection).delete(workspace_name:, coverage_store_name:)
    end

    def self.delete_shapefile(workspace_name:, id:, connection: nil)
      data_store_name = "berkeley_#{id}"
      DataStore.new(connection).delete(workspace_name:, data_store_name:)
    end

    def self.geotiff(workspace_name:, file_path:, id:, title: nil, connection: nil)
      coverage_store_name = "berkeley_#{id}"
      create_workspace(workspace_name:, connection:)
      create_coverage_store(workspace_name:, coverage_store_name:, url: file_path,
                            connection:)
      create_coverage(workspace_name:, coverage_store_name:, coverage_name: id, title:,
                      connection:)
    end

    def self.shapefile(workspace_name:, file_path:, id:, title: nil, connection: nil)
      data_store_name = "berkeley_#{id}"
      create_workspace(workspace_name:, connection:)
      create_data_store(workspace_name:, data_store_name:, url: file_path, connection:)
      create_feature_type(workspace_name:, data_store_name:, feature_type_name: id, title:,
                          connection:)
    end

    def self.root
      Pathname.new(File.expand_path('../..', __dir__))
    end

    class Error < StandardError
    end
  end
end
