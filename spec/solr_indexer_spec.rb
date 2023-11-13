# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gingr::SolrIndexer do
  let(:url) { 'http://solr:8983/solr/geodata-test' }
  let(:solr) { instance_double(RSolr::Client) }

  describe '#initialize' do
    before do
      allow(RSolr).to receive(:connect).and_return(solr)
    end

    it 'should initialize' do
      described_class.new(url)
      expect(RSolr).to have_received(:connect).with(
        url:,
        adapter: :net_http_persistent
      )
    end
  end

  describe '#update' do
    let(:file_path) { 'spec/fixture/jsonfile/berkeley_public_pdf.json' }
    let(:doc) { JSON.parse(File.read(file_path)) }

    before do
      allow(solr).to receive(:update)
      allow(RSolr).to receive(:connect).and_return(solr)
      solr_indexer.update(file_path)
    end

    context 'update reference urls' do
      let(:solr_indexer) { described_class.new(url, reference_urls) }
      let(:reference_urls) do
        { 'geoserver_secure' => 'http://fake_geoserver_secure:8081',
          'geoserver' => 'http://fake_geoserver:8080',
          'download' => 'https://fake_spatial.lib.berkeley.edu' }
      end

      it 'should call solr' do
        expect(solr).to have_received(:update).with(
          params: { commitWithin: 5000, overwrite: true },
          data: [[doc].flatten[0]].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'should call the update reference field method' do
        expect(solr_indexer.need_update_reference_urls).to eq(true)
      end
    end

    context 'not update reference urls' do
      let(:solr_indexer) { described_class.new(url) }
      it 'should not call the update reference field method' do
        solr_indexer.update(file_path)
        expect(solr_indexer.need_update_reference_urls).to eq(false)
      end
    end
  end

  describe '#commit' do
    before do
      allow(RSolr).to receive(:connect).and_return(solr)
      allow(solr).to receive(:commit)
    end

    it 'should initialize' do
      solr_indexer = described_class.new(url)
      solr_indexer.commit
      expect(solr_indexer.solr).to have_received(:commit)
    end
  end
end
