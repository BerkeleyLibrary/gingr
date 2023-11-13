# frozen_string_literal: true

# monkey-patch first
require_relative 'monkeypatch/geoserver/publish'

require_relative 'gingr/cli'
require_relative 'gingr/config'
require_relative 'gingr/data_handler'
require_relative 'gingr/geoserver_publisher'
require_relative 'gingr/import_util'
require_relative 'gingr/solr_indexer'

module Gingr
  #
end
