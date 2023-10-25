# frozen_string_literal: true

module Gingr
  # util methods
  module ImportUtil
    def publish_geoservers(geofile_names, options)
      publish_geoserver_files(geofile_names[:public], options[:geoserver_url], true)
      publish_geoserver_files(geofile_names[:ucb], options[:geoserver_secure_url], false)
    end

    def index_solr_from_dir(directory_path, url, reference_urls)
      indexer = SolrIndexer.new(url, reference_urls)
      Find.find(directory_path) do |path|
        next unless File.extname(path).downcase == '.json'

        indexer.update(path)
      rescue RSolr::Error::Http => e
        puts "Response body: #{e.response}"
      end
      indexer.solr.commit
    end

    def get_reference_urls(options)
      update_reference_field = options[:update_reference_field]
      return {} unless update_reference_field

      hash = {}
      Config.reference_urls.each_key do |key|
        url = options[key.to_s] || ENV.fetch("#{key.upcase}_URL")
        hash[key.to_s] = reference_url(url) if url
      end
      hash
    end

    def root_path
      File.expand_path('..', __dir__)
    end

    private

    def publish_geoserver_files(files, url, is_public)
      return if files.empty?

      url ||= is_public ? ENV.fetch('GEOSERVER_URL', nil) : ENV.fetch('GEOSERVER_SECURE_URL', nil)
      publisher = GeoserverPublisher.new(url)
      publisher.batch_update(files)
    end

    def reference_url(url)
      uri = URI(url)
      port = uri.port == 8080 ? ':8080' : ''
      "#{uri.scheme}://#{uri.host}#{port}"
    end
  end
end
