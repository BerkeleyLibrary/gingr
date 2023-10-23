# frozen_string_literal: true

# referenced domain defined in pre-ingestion tool
module Gingr
  # config info
  module Config
    # value: domain from pre-ingestion tool
    @reference_urls = {
      geoserver_secure: 'https://geoservices-secure.lib.berkeley.edu',
      geoserver: 'https://geoservices.lib.berkeley.edu/geoserver',
      download: 'https://spatial.lib.berkeley.edu'
    }

    # dirname where all geofile related ingestion files located inside the ingestion zip file
    @geofile_ingestion_dirname = 'ingestion_files'

    class << self
      attr_accessor :name_domain_hash, :geofile_ingestion_dirname

      include Config
    end
  end
end
