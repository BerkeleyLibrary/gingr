# frozen_string_literal: true

require 'berkeley_library/logging'

# Gingr
module Gingr
  # config info
  module Config
    # value: urls poplated for reference field in pre-ingestion tool
    @reference_urls = {
      geoserver_secure: 'https://geoservices-secure.lib.berkeley.edu',
      geoserver: 'https://geoservices.lib.berkeley.edu/geoserver',
      download: 'https://spatial.lib.berkeley.edu'
    }

    # dirname where all geofile related ingestion files located inside the ingestion zipfile
    @geofile_ingestion_dirname = 'ingestion_files'

    @logger = BerkeleyLibrary::Logging::Loggers.new_readable_logger('tmp/import.log')

    class << self
      attr_accessor :name_domain_hash, :geofile_ingestion_dirname, :logger

      include Config
    end
  end
end
