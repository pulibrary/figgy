# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "LinkedData::Resource" do
  subject(:linked_resource) { LinkedData::LinkedResource.for(resource: resource) }

  before do
    raise "resource must be set with `let(:resource)`" unless
      defined? resource
  end

  describe "#as_jsonld" do
    it "provides the base local fields" do
      expect(linked_resource.as_jsonld).to be_a Hash
      expect(linked_resource.as_jsonld).not_to be_empty
      expect(linked_resource.as_jsonld["@context"]).to eq(
        [
          "https://bibdata.princeton.edu/context.json",
          {
            "wgs84": "http://www.w3.org/2003/01/geo/wgs84_pos#",
            "latitude": {
              "@id": "wgs84:lat"
            },
            "longitude": {
              "@id": "wgs84:lon"
            }
          }
        ]
      )
    end
  end

  describe ".new" do
    subject(:linked_resource) { LinkedData::LinkedResource.for(resource: custom_resource) }
    before do
      class MyCustomResource < Valkyrie::Resource
        attribute :title, Valkyrie::Types::Set

        def linked_resource
          LinkedData::LinkedResource.new(resource: self)
        end
      end
    end

    after do
      Object.send(:remove_const, :MyCustomResource)
    end

    let(:custom_resource) { MyCustomResource.new(title: "test title 1") }
    it "#title" do
      expect(linked_resource.title).to include RDF::Literal.new("test title 1", language: :eng)
    end
  end
end
