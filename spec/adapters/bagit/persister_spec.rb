# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe Bagit::Persister do
  let(:base_adapter) do
    Bagit::MetadataAdapter.new(
      base_path: Rails.root.join("tmp", "bags")
    )
  end
  let(:adapter) { base_adapter }
  let(:query_service) { adapter.query_service }
  let(:persister) { adapter.persister }
  it_behaves_like "a Valkyrie::Persister"
  after do
    persister.wipe!
  end

  context "when nested in an existing bag" do
    let(:adapter) do
      base_adapter.for(bag_id: resource.id)
    end
    let(:resource) do
      base_adapter.persister.save(resource: ScannedResource.new(title: "Parent"))
    end
    it_behaves_like "a Valkyrie::Persister"
    it "saves resources in a nested bag" do
      resource
      new_resource = adapter.persister.save(resource: ScannedResource.new(title: "Child"))
      expect(File.exist?(Rails.root.join("tmp", "bags", resource.id.to_s, "metadata", "#{resource.id}.jsonld"))).to eq true
      expect(File.exist?(Rails.root.join("tmp", "bags", resource.id.to_s, "metadata", "#{new_resource.id}.jsonld"))).to eq true
      adapter.persister.delete(resource: new_resource)
      expect { adapter.query_service.find_by(id: resource.id) }.not_to raise_error
    end
  end
end
