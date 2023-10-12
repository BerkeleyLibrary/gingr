# frozen_string_literal: true

# referenced domain defined in pre-ingestion tool
module Gingr
  # config info
  module Config
    # key: environment varable name
    # value: domain from pre-ingestion tool
    @env_domains = {
      GEOSERVER_SECURE_URL: 'geoservices-secure.lib.berkeley.edu',
      GEOSERVER_URL: 'geoservices.lib.berkeley.edu/geoserver/',
      DOWNLOAD_URL: 'spatial.lib.berkeley.edu'
    }
    class << self
      attr_accessor :domains

      include Config
    end
  end
end
