# frozen_string_literal: true
require 'spec_helper'
require 'gingr/geoserver_publisher'

RSpec.describe Gingr::GeoserverPublisher do
  subject { Gingr::GeoserverPublisher.new(connection, default:, remote_root:, workspace_name:) }
  let(:connection) { nil }
  let(:default) { nil }
  let(:remote_root) { nil }
  let(:workspace_name) { nil }

  around(:each) do |test|
    orig_geoserver_url = ENV.delete('GEOSERVER_URL')
    orig_geoserver_secure_url = ENV.delete('GEOSERVER_SECURE_URL')
    test.run
  ensure
    ENV['GEOSERVER_URL'] = orig_geoserver_url
    ENV['GEOSERVER_SECURE_URL'] = orig_geoserver_secure_url
  end

  describe '.new' do
    context 'given a connection string' do
      let(:connection) { 'http://admin:geoserver@geoserver:8080/geoserver' }

      it 'initialized with a connection string' do
        expect(subject.connection.config['url']).to eq 'http://geoserver:8080/geoserver/rest/'
        expect(subject.connection.config['user']).to eq 'admin'
        expect(subject.connection.config['password']).to eq 'geoserver'
      end
    end

    context 'ENV[GEOSERVER_*_URL] are set' do
      before do
        ENV['GEOSERVER_URL'] = 'https://public_user:public_pass@geoserver-public.lib.berkeley.edu/geoserver'
        ENV['GEOSERVER_SECURE_URL'] = 'https://secure_user:secure_pass@geoserver-secure.lib.berkeley.edu/geoserver'
      end

      it 'falls back to GEOSERVER_URL' do
        expect(subject.connection.config['url']).to eq 'https://geoserver-public.lib.berkeley.edu/geoserver/rest/'
        expect(subject.connection.config['user']).to eq 'public_user'
        expect(subject.connection.config['password']).to eq 'public_pass'
      end

      context 'it is secure' do
        let(:default) { :geoserver_secure_url }

        it 'falls back to GEOSERVER_SECURE_URL' do
          expect(subject.connection.config['url']).to eq 'https://geoserver-secure.lib.berkeley.edu/geoserver/rest/'
          expect(subject.connection.config['user']).to eq 'secure_user'
          expect(subject.connection.config['password']).to eq 'secure_pass'
        end
      end
    end

    context 'nothing is given and ENV are not set' do
      it 'falls back to the Config defaults' do
        expect(subject.connection.config['url']).to eq 'http://geoserver:8080/geoserver/rest/'
        expect(subject.connection.config['user']).to eq 'admin'
        expect(subject.connection.config['password']).to eq 'geoserver'
      end

      context 'it is secure' do
        let(:default) { :geoserver_secure_url }

        it 'falls back to the Config defaults' do
          expect(subject.connection.config['url']).to eq 'http://geoserver-secure:8080/geoserver/rest/'
          expect(subject.connection.config['user']).to eq 'admin'
          expect(subject.connection.config['password']).to eq 'geoserver'
        end
      end
    end
  end

  describe '.parse_connection_string' do
    it 'correctly infers the REST URL from a baseurl' do
      connstring = 'http://admin:geoserver@geoserver:8080/geoserver'
      url, user, password = described_class.parse_connection_string(connstring)
      expect(url).to eq 'http://geoserver:8080/geoserver/rest/'
      expect(user).to eq 'admin'
      expect(password).to eq 'geoserver'
    end
  end

  describe '#create_workspace', unless: running_in_ci? do
    let(:workspace_name) { "test-UCB-#{Random.rand(1000)}" }
    let(:workspace_client) { Geoserver::Publish::Workspace.new(subject.connection) }

    after { workspace_client.delete(workspace_name:) }

    it 'creates a workspace if one does not already exist' do
      expect { subject.create_workspace }
        .to change { workspace_client.find(workspace_name:) }
        .from(nil)
    end

    it 'is a no-op if the workspace already exists' do
      workspace_client.create(workspace_name:)
      expect { subject.create_workspace }
        .not_to change { workspace_client.find(workspace_name:) }
    end
  end

  describe 'publish', unless: running_in_ci? do
    let(:workspace_name) { "test-UCB-#{Random.rand(1000)}" }
    let(:workspace_client) { Geoserver::Publish::Workspace.new(subject.connection) }

    around do |test|
      workspace_client.create(workspace_name:)
      Gingr::DataHandler.processing_root = '/opt/app/tmp'
      Gingr::DataHandler.spatial_root = '/opt/app/data/spatial'
      Gingr::DataHandler.geoserver_root = '/opt/app/data/geoserver'
      Gingr::DataHandler.extract_and_move('spec/fixture/zipfile/vector_restricted_with_attachment.zip')
      Gingr::DataHandler.extract_and_move('spec/fixture/zipfile/vector.zip')
      Gingr::DataHandler.extract_and_move('spec/fixture/zipfile/raster_public.zip')
      test.run
    ensure
      workspace_client.delete(workspace_name:)
    end

    context 'with a public geoserver' do
      it 'publishes a shapefile' do
        subject.publish 'fk4hm6vj5q.shp'
      end

      it 'publishes a batch of shapefiles' do
        subject.batch_publish %w(fk4hm6vj5q.shp fk4cv64r2x.shp)
      end

      it 'publishes a raster file' do
        # pending 'Missing datafile'
        subject.publish 'fk4mk7zb4q.tif'
      end
    end

    context 'with the secure geoserver' do
      let(:default) { :geoserver_secure_url }

      it 'publishes a shapefile' do
        subject.publish 's76412.shp'
      end
    end
  end
end
