# frozen_string_literal: true

require 'geoserver/publish'
require 'nokogiri'

# filepath = 'file:///data/UCB/berkeley-s7wx16/s7wx16.shp'

# filepath = 'file:///srv/geofiles/berkeley-s7wx16/s7wx16.shp'

host = 'http://localhost'
# host = "http://host.docker.internal"

new_conn = Geoserver::Publish::Connection.new({ 'url' => "#{host}:8080/geoserver/rest", 'user' => 'admin',
                                                'password' => 'geoserver' })
Geoserver::Publish.shapefile(connection: new_conn, workspace_name: 'UCB', file_path: filepath, id: 's7wx16',
                             title: 's7wx16')
