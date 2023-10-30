#!/bin/sh

# unpack zipfile
echo "1 - unpack zipfile starting..."
ruby bin/import unpack spec/data/zipfile/test_public.zip
echo "unpack zipfile ends"

# index solr
echo "2 - index solr starting..."
ruby bin/import solr tmp/test_public/
echo "index solr ends"

# publish geoserver (need testing both public and restricted geoserver?)
# echo "3.1 - create geoserver workspace ..."
# ruby bin/import geoserver_workspace UCB
# echo "create create geoserver workspace ends"

# echo "3.2 - publish vector to geoserver starting..."
# ruby bin/import geoserver aaaa.shp
# echo "publish vector to geoserver ends"

# echo "3.3 - publish raster to geoserver starting..."
# ruby bin/import geoserver bbbb.TIFF
# echo "publish raster to geoserver ends"



