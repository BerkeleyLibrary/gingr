# frozen_string_literal: true

require 'geoserver/publish'


# filepath = 'file:///data/UCB/berkeley-s7wx16/s7wx16.shp'

# host = 'http://localhost'
host = 'http://host.docker.internal'

new_conn = Geoserver::Publish::Connection.new({ 'url' => "#{host}:8080/geoserver/rest", 'user' => 'admin',
                                                'password' => 'geoserver' })
# Geoserver::Publish.shapefile(connection: new_conn, workspace_name: 'UCB', file_path: filepath, id: 's7wx16',
#                              title: 's7wx16')
# filepath = 'file:///srv/geofiles/berkeley-s7wx16/s7wx16.shp'
# Geoserver::Publish.shapefile(connection: new_conn, workspace_name: 'UCB', file_path: filepath, id: 's7wx16',
#                              title: 's7wx16')

# Geoserver::Publish.delete_shapefile(connection: new_conn, workspace_name: 'UCB', id: 's7wx16')
# Geoserver::Publish.delete_shapefile(connection: new_conn, workspace_name: 'UCB', id: 's7zt25')

name = 's7zt25'
filepath = "file:///srv/geofiles/berkeley-#{name}/#{name}.shp"
id = name
title = name
Geoserver::Publish.shapefile(connection: new_conn, workspace_name: 'UCB', file_path: filepath, id:, title:)
# #
# name = "s7wx16"
# filepath = "file:///data/UCB/berkeley-#{name}/#{name}.shp"
# id = name
# title = name
# Geoserver::Publish.shapefile(connection: new_conn, workspace_name: 'UCB', file_path: filepath, id:, title:)

# filepath = 'file:///srv/geofiles/berkeley_s5048_1/s5048_1.tif'
# id = 's5048_1'
# title = 's5048_1'
# Geoserver::Publish.geotiff(connection: new_conn, workspace_name: 'UCB', file_path: filepath, id:, title:)
