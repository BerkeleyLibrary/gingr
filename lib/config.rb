# frozen_string_literal: true

# referenced domain defined in pre-ingestion tool
module Gingr
  # config info
  module Config
    # value: domain from pre-ingestion tool
    @domain_names = {
      geoserver_secure: 'geoservices-secure.lib.berkeley.edu',
      geoserver: 'geoservices.lib.berkeley.edu/geoserver/',
      download: 'spatial.lib.berkeley.edu'
    }

    # dirname where all geofile related ingestion files located inside the ingestion zip file
    @geofile_ingestion_dirname = 'ingestion_files'

    class << self
      attr_accessor :name_domain_hash, :geofile_ingestion_dirname

      include Config
    end
  end
end
