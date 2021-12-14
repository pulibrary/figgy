# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedSimpleResource do
  subject(:linked_resource) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.create_for_repository(:simple_resource, date_range: date_range) }
  let(:date_range) { DateRange.new(start: "2013", end: "2017") }
  let(:resource_factory) { :simple_resource }

  it_behaves_like "LinkedData::Resource::WithDateRange"
  it_behaves_like "LinkedData::Resource"

  describe "as_jsonld" do
    context "when it has a start canvas" do
      it "doesn't display it" do
        resource = FactoryBot.create_for_repository(
          :simple_resource,
          start_canvas: SecureRandom.uuid
        )

        expect(resource.linked_resource.as_jsonld["start_canvas"]).to be_nil
      end
    end

    context "when it has an actor field with Strings, Groupings and RDF literals" do
      let(:resource) do
        FactoryBot.create_for_repository(
          :simple_resource,
          actor: [
            RDF::Literal.new("هدى سلطان", language: "ara-Arab"),
            "Name String",
            Grouping.new(
              elements: [
                RDF::Literal.new("Milījī, Maḥmūd", language: "ara-Latn"),
                RDF::Literal.new("محمود المليجي", language: "ara-Arab")
              ]
            )
          ]
        )
      end

      it "provides appropriate json structure" do
        jsonld = linked_resource.as_jsonld
        expect(jsonld["actor"].first).to be_a RDF::Literal
        expect(jsonld["actor"][1]).to eq "Name String"
        expect(jsonld["actor"].last["grouping"].map(&:class)).to eq [RDF::Literal, RDF::Literal]
      end
    end

    context "when it has a coverage point" do
      let(:lat) { 40.34781552 }
      let(:lon) { -74.65862657 }
      let(:resource) do
        FactoryBot.create_for_repository(
          :simple_resource,
          coverage_point: [
            CoveragePoint.new(
              lat: lat,
              lon: lon
            )
          ]
        )
      end

      it "provides appropriate json structure" do
        jsonld = linked_resource.as_jsonld
        expect(jsonld["latitude"]).to eq [lat.to_s]
        expect(jsonld["longitude"]).to eq [lon.to_s]
        expect { jsonld.fetch("coverage_point") }.to raise_error(KeyError)
      end
    end
  end
end
