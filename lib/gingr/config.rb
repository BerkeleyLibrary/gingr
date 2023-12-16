# frozen_string_literal: true

module Gingr
  module Config
    # value: urls populated for reference field in pre-ingestion tool
    @reference_urls = {
      geoserver_secure_url: 'https://geoservices-secure.lib.berkeley.edu/',
      geoserver_url: 'https://geoservices.lib.berkeley.edu/geoserver/',
      spatial_url: 'https://spatial.lib.berkeley.edu/'
    }

    # dirname where all geofile related ingestion files located inside the ingestion zipfile
    @geofile_ingestion_dirname = 'ingestion_files'

    # default options for commands
    @default_options = {
      geoserver_secure_url: 'http://admin:geoserver@geoserver_secure:8080/geoserver/rest/',
      geoserver_url: 'http://admin:geoserver@geoserver:8080/geoserver/rest/',
      spatial_url: 'https://spatial.lib.berkeley.edu',
      spatial_root: 'data/spatial/',
      geoserver_root: 'data/geoserver/',
      solr_url: 'http://solr:8983/solr/geodata-test'
    }

    class << self
      attr_accessor :geofile_ingestion_dirname, :reference_urls, :default_options

      include Config
    end
  end
end
