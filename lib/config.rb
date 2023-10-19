# frozen_string_literal: true

# referenced domain defined in pre-ingestion tool
module Gingr
  # config info
  module Config
    # key: class attribute names defined in solr_index.rb
    # value: domain from pre-ingestion tool
    @name_domain_hash = {
      geoserver_secure_url: 'geoservices-secure.lib.berkeley.edu',
      geoserver_url: 'geoservices.lib.berkeley.edu/geoserver/',
      download_url: 'spatial.lib.berkeley.edu'
    }

    # dirname where all geofile related ingestion files located inside the ingestion zip file
    @geofile_ingestion_dirname = 'ingestion_files'

    class << self
      attr_accessor :name_domain_hash, :geofile_ingestion_dirname

      include Config
    end
  end
end
