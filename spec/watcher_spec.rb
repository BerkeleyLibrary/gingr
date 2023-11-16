# frozen_string_literal: true
require 'open3'
require 'spec_helper'
require 'fileutils'

# Class for mocking returned Process::Status objects
class MockStatus
  class << self
    def successful
      new(true)
    end

    def failed
      new(false)
    end
  end

  def initialize(success)
    @success = success
  end

  def success?
    @success
  end
end

RSpec.describe Gingr::Watcher do
  before(:each) { FileUtils.rm_rf Dir.glob('/opt/app/data/gingr/*/*') }

  subject(:watcher) { Gingr::Watcher.new('/opt/app/data/gingr', options) }

  let(:options) do
    {
      geoserver_root: '/opt/app/data/geoserver',
      geoserver_secure_url: 'http://admin:geoserver@geoserver-secure:8080/geoserver/rest/',
      geoserver_url: 'http://admin:geoserver@geoserver:8080/geoserver/rest/',
      solr_url: 'http://solr:8983/solr/geodata-test',
      spatial_root: '/opt/app/data/spatial',
      update_reference_field: true,
    }
  end

  context 'a valid watcher' do
    describe 'option handling' do
      it 'parses a hash of options into a list of CLI arguments' do
        expect(watcher.arguments).to eq %w(
          --geoserver-root /opt/app/data/geoserver
          --geoserver-secure-url http://admin:geoserver@geoserver-secure:8080/geoserver/rest/
          --geoserver-url http://admin:geoserver@geoserver:8080/geoserver/rest/
          --solr-url http://solr:8983/solr/geodata-test
          --spatial-root /opt/app/data/spatial
          --update-reference-field true
        )

        watcher.options[:update_reference_field] = false
        expect(watcher.arguments.last(2)).to eq %w(--update-reference-field false)
      end

      it 'passes arguments to `gingr all`' do
        expect(Open3).to receive(:capture3).with(*%w(
          gingr all /opt/app/data/gingr/ready/vector.zip
            --geoserver-root /opt/app/data/geoserver
            --geoserver-secure-url http://admin:geoserver@geoserver-secure:8080/geoserver/rest/
            --geoserver-url http://admin:geoserver@geoserver:8080/geoserver/rest/
            --solr-url http://solr:8983/solr/geodata-test
            --spatial-root /opt/app/data/spatial
            --update-reference-field true
        )).and_return(['', '', MockStatus.successful])

        copy_zipfile_to_ready('vector.zip')
        watcher.exec_gingr_all!('/opt/app/data/gingr/ready/vector.zip')
      end
    end

    it 'moves successfully processed files to the processed directory' do
      expect(Open3).to receive(:capture3).and_return(['', '', MockStatus.successful])

      copy_zipfile_to_ready('vector.zip')
      watcher.exec_gingr_all!('/opt/app/data/gingr/ready/vector.zip')
      expect(File).to exist('/opt/app/data/gingr/processed/vector.zip')
    end

    it 'processes newly added files and keeps processing on error' do
      watcher.start

      (1..4).each do |i|
        exp = expect(Open3).to receive(:capture3).with(*%W(
          gingr all /opt/app/data/gingr/ready/vector#{i}.zip
            --geoserver-root /opt/app/data/geoserver
            --geoserver-secure-url http://admin:geoserver@geoserver-secure:8080/geoserver/rest/
            --geoserver-url http://admin:geoserver@geoserver:8080/geoserver/rest/
            --solr-url http://solr:8983/solr/geodata-test
            --spatial-root /opt/app/data/spatial
            --update-reference-field true
        ))

        if i.odd?
          exp.and_raise(Gingr::Watcher::SubprocessError)
        else
          exp.and_return(['', '', MockStatus.successful])
        end

        copy_zipfile_to_ready('vector.zip', "vector#{i}.zip")
        sleep 2
      end
    end
  end

  context 'a watcher with invalid options' do
    let(:options) { { unexpected_argument: true } }

    it 'moves failed files and the logs to the failed directory' do
      expect(Open3).to receive(:capture3).and_return(['', 'Unknown switches', MockStatus.failed])
      copy_zipfile_to_ready('vector.zip')

      expect { watcher.exec_gingr_all!('/opt/app/data/gingr/ready/vector.zip') }.to raise_error(Gingr::Watcher::SubprocessError)
      expect(File).to exist('/opt/app/data/gingr/failed/vector.zip')
      expect(File).to exist('/opt/app/data/gingr/failed/vector.log')
      expect(File.read('/opt/app/data/gingr/failed/vector.log')).to match(/Unknown switches/)
    end
  end

  context 'a watcher with an invalid root directory' do
    subject(:watcher) { Gingr::Watcher.new('/path/does-not-exist') }

    it 'fails to initialize' do
      expect { watcher }.to raise_error(Gingr::Watcher::DirectoryError)
    end
  end

  private

  def copy_zipfile_to_ready(filename, newname = nil)
    newname ||= filename
    FileUtils.cp("/opt/app/spec/fixture/zipfile/#{filename}", "/opt/app/data/gingr/ready/#{newname}")
  end
end
