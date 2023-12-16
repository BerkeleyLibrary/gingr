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

    class << self
      attr_accessor :geofile_ingestion_dirname
      attr_accessor :reference_urls

      include Config
    end
  end
end
