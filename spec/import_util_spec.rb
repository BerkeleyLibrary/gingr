# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gingr::ImportUtil do
  let(:reference_urls) do
    {
      download_url: 'https://spatial_fake.lib.berkeley.edu',
      geoserver_secure_url: 'http://geoserver_fake_secure:8081',
      geoserver_url: 'http://geoserver_fake:8080'
    }
  end

  let(:options) do
    {
      update_reference_field: false,
      geoserver_secure_url: 'http://admin:geoserver@geoserver_fake_secure:8081/geoserver/rest/',
      geoserver_url: 'http://admin:geoserver@geoserver_fake:8080/geoserver/rest/',
      download_url: 'https://spatial_fake.lib.berkeley.edu'
    }
  end

  it 'should not update the reference field' do
    expect(Gingr::ImportUtil.get_reference_urls(options)).to eq({})
  end

  it 'should update the reference field hash' do
    options[:update_reference_field] = true
    expect(Gingr::ImportUtil.get_reference_urls(options)).to eq(reference_urls)
  end
end
