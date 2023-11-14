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

  context 'a valid watcher' do
    subject :watcher do
      Gingr::Watcher.new(
        '/opt/app/data/gingr',
        '--solr-url=http://solr:8983/solr/geodata-test',
        '--geoserver-url=http://admin:geoserver@geoserver:8080/geoserver/rest/',
        '--geoserver-root=/opt/app/data/geoserver',
        '--geoserver-secure-root=/opt/app/data/geoserver',
        '--spatial-root=/opt/app/data/spatial',
        '--update-reference-field',
      )
    end

    it 'passes arguments to `gingr all`' do
      expect(Open3).to receive(:capture3).with('gingr', 'all',
        '/opt/app/data/gingr/ready/vector.zip',
        '--solr-url=http://solr:8983/solr/geodata-test',
        '--geoserver-url=http://admin:geoserver@geoserver:8080/geoserver/rest/',
        '--geoserver-root=/opt/app/data/geoserver',
        '--geoserver-secure-root=/opt/app/data/geoserver',
        '--spatial-root=/opt/app/data/spatial',
        '--update-reference-field',
      ).and_return(['', '', MockStatus.successful])

      copy_zipfile_to_ready('vector.zip')
      watcher.exec_gingr_all!('/opt/app/data/gingr/ready/vector.zip')
    end

    it 'moves successfully processed files to the processed directory' do
      expect(Open3).to receive(:capture3).and_return(['', '', MockStatus.successful])

      copy_zipfile_to_ready('vector.zip')
      watcher.exec_gingr_all!('/opt/app/data/gingr/ready/vector.zip')
      expect(File).to exist('/opt/app/data/gingr/processed/vector.zip')
    end

    it 'processes newly added files and keeps processing on error' do
      watcher.start

      (1..5).each do |i|
        expection = expect(watcher)
          .to receive(:exec_gingr_all!)
          .with "/opt/app/data/gingr/ready/vector#{i}.zip"
        expection.and_raise if i.odd?

        copy_zipfile_to_ready('vector.zip', "vector#{i}.zip")
        sleep 3
      end
    end
  end

  context 'a watcher with invalid arguments' do
    subject :watcher do
      Gingr::Watcher.new(
        '/opt/app/data/gingr',
        '--solr-url=http://solr:8983/solr/geodata-test',
        '--geoserver-url=http://admin:geoserver@geoserver:8081/geoserver/rest/',
        '--invalid-argument'
      )
    end

    it 'moves failed files and the logs to the failed directory' do
      copy_zipfile_to_ready('vector.zip')

      expect(Open3).to receive(:capture3).and_return(['', 'Unknown switches', MockStatus.failed])
      expect { watcher.exec_gingr_all!('/opt/app/data/gingr/ready/vector.zip') }.to raise_error Gingr::Watcher::SubprocessError
      expect(File).to exist('/opt/app/data/gingr/failed/vector.zip')
      expect(File).to exist('/opt/app/data/gingr/failed/vector.log')
      expect(File.read('/opt/app/data/gingr/failed/vector.log')).to match(/Unknown switches/)
    end
  end

  context 'a watcher that cannot write to its watch dirs' do
    subject :watcher do
      Gingr::Watcher.new('/opt/app/data/gingr-does-not-exist')
    end

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
