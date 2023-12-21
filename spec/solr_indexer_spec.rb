# frozen_string_literal: true
require 'spec_helper'
require 'find'
require 'gingr/solr_indexer'

RSpec.describe Gingr::SolrIndexer do
  around(:each) do |test|
    original_solr_url = ENV['SOLR_URL']
    test.run
  ensure
    ENV['SOLR_URL'] = original_solr_url
  end

  describe '#initialize' do
    it 'initializes a solr client with the given url' do
      indexer = Gingr::SolrIndexer.new('http://solr-from-init/')
      expect(indexer.solr.uri.to_s).to eq 'http://solr-from-init/'
    end

    it 'falls back to ENV["SOLR_URL"] if it is set' do
      ENV['SOLR_URL'] = 'http://solr-from-env/'
      indexer = Gingr::SolrIndexer.new
      expect(indexer.solr.uri.to_s).to eq 'http://solr-from-env/'
    end

    it 'falls back to the config' do
      ENV.delete 'SOLR_URL'
      indexer = Gingr::SolrIndexer.new
      expect(indexer.solr.uri.to_s).to eq 'http://solr:8983/solr/geodata-test/'
    end
  end

  describe '#update_reference_urls!' do
    let(:document) { JSON.load_file('spec/fixture/jsonfile/berkeley_public_pdf.json') }

    it 'does nothing if reference_urls are nil' do
      indexer = Gingr::SolrIndexer.new
      expect { indexer.update_reference_urls! document }.not_to change { document }
    end

    it 'updates references if configured to do so' do
      refs = { geoserver_url: 'http://geoserver-at-init/' }
      indexer = Gingr::SolrIndexer.new(nil, refs)
      expect { indexer.update_reference_urls! document }.to change { document }
      expect(document['dct_references_s']).to match 'http://geoserver-at-init/'
    end
  end

  describe '#index_directory' do
    it 'adds all .json files to solr' do
      files = ['foo.xml', 'bar.json', 'baz.json'].shuffle
      expect(Find).to receive(:find).with('directory').and_return files
      Gingr::SolrIndexer.any_instance.stub(:add)

      indexer = Gingr::SolrIndexer.new
      indexer.index_directory('directory')
      expect(indexer).to have_received(:add).with('bar.json')
      expect(indexer).to have_received(:add).with('baz.json')
      expect(indexer).not_to have_received(:add).with('foo.xml')
    end
  end

  describe '#add' do
    let(:document) { JSON.load_file document_path }
    let(:document_path) { 'spec/fixture/jsonfile/berkeley_public_pdf.json' }

    it 'passes documents to the rsolr client' do
      solr = spy(RSolr::Client)
      indexer = Gingr::SolrIndexer.new(solr)
      indexer.add(document)
      expect(solr).to have_received(:add).with(document)
    end

    it 'automatically loads filepaths as JSON' do
      solr = spy(RSolr::Client)
      indexer = Gingr::SolrIndexer.new(solr)
      indexer.add(document_path)
      expect(solr).to have_received(:add).with(document)
    end

    it 'modifies reference urls' do
      solr = spy(RSolr::Client)
      refs = { geoserver_url: 'http://geoserver-from-init/' }
      indexer = Gingr::SolrIndexer.new(solr, refs)
      expect { indexer.add(document) }.to change { document }
      expect(document['dct_references_s']).to match('http://geoserver-from-init/')
      expect(solr).to have_received(:add).with(document)
    end
  end
end
