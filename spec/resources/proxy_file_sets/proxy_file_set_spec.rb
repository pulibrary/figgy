# frozen_string_literal: true

# Generated with `rails generate valkyrie:model ProxyFileSet`
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ProxyFileSet do
  let(:resource_klass) { described_class }
  let(:proxy) { described_class.new }
  let(:proxied_id) { Valkyrie::ID.new("some_id") }

  it_behaves_like "a Valkyrie::Resource"

  it "has a label" do
    proxy.label = ["Pure Imagination"]
    expect(proxy.label).to eq ["Pure Imagination"]
  end

  it "has visibility" do
    proxy.visibility = ["restricted"]
    expect(proxy.visibility).to eq ["restricted"]
  end

  it "has an id of the FileSet it proxies" do
    proxy.proxied_file_id = proxied_id
    expect(proxy.proxied_file_id).to eq proxied_id
  end
end
