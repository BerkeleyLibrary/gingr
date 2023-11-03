require 'spec_helper'
require_relative '../lib/solr_indexer'

module Gingr
  describe SolrIndexer do
    let(:url) { ENV['SOLR_URL'] || 'http://solr:8983/solr/geodata-test' }
    let(:file_path) { 'spec/fixture/jsonfile/berkeley_public_pdf.json' }
    context '# not empty reference_urls' do
      let(:reference_urls) do
        { 'geoserver_secure' => 'http://fake_geoserver_secure:8081',
          'geoserver' => 'http://fake_geoserver:8080',
          'download' => 'https://fake_spatial.lib.berkeley.edu' }
      end
      let(:solr_indexer) { SolrIndexer.new(url, reference_urls) }
      let(:record) do
        doc = JSON.parse(File.read(file_path))
        [doc].flatten[0]
      end

      it 'should call the update reference field method' do
        expect(solr_indexer).to receive(:update_reference_urls!).with(record)
        solr_indexer.update(file_path)
      end

      it 'should update reference field' do
        solr_indexer.send(:update_reference_urls!, record)
        # change to not use this long string when getting real data
        updated_reference_field = '{"http://www.opengis.net/def/serviceType/ogc/wfs":"http://fake_geoserver:8080/wfs","http://www.opengis.net/def/serviceType/ogc/wms":"http://fake_geoserver:8080/wms","http://www.isotc211.org/schemas/2005/gmd/":"https://spatial.ucblib.org/metadata/berkeley-s7038h/iso19139.xml","http://schema.org/downloadUrl":"https://spatial.ucblib.org/public/berkeley-s7038h/data.zip","http://lccn.loc.gov/sh85035852":"https://spatial.ucblib.org/public/berkeley-s7038h/x.pdf"}'
        expect(record['dct_references_s']).to eq updated_reference_field
      end
    end

    context '# empty reference_urls' do
      it 'should not call the update reference field method' do
        solr_indexer = SolrIndexer.new(url, {})
        solr_indexer.update(file_path)
        expect(solr_indexer).not_to receive(:update_reference_urls!)
      end
    end
  end
end
