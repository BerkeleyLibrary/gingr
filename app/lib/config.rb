# frozen_string_literal: true

# referenced domain defined in pre-ingestion tool
module Gingr
  # config info
  module Config
    @domains = {
      GEOSERVER_SECURE: 'geoservices-secure.lib.berkeley.edu',
      GEOSERVER: 'geoservices.lib.berkeley.edu/geoserver/',
      DOWNLOAD: 'spatial.lib.berkeley.edu'
    }
    class << self
      attr_accessor :domains

      include Config
    end
  end
end
