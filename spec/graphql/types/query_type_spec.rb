# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::QueryType do
  let(:context) { { ability: ability, change_set_persister: change_set_persister } }
  let(:ability) { instance_double(Ability) }
  let(:change_set_persister) { GraphqlController.change_set_persister }

  describe "field definitions" do
    subject { described_class }
    let(:context) { {} }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:resource).of_type(Types::Resource) }
    it { is_expected.to have_field(:resourcesByBibid) }
  end

  context "when the user can read the resource" do
    before do
      allow(ability).to receive(:can?).with(:read, anything).and_return(true)
    end

    describe "resource field" do
      subject { described_class.fields["resource"] }
      it { is_expected.to accept_arguments(id: "ID!") }
      it "can return a resource by ID" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        type = described_class.new(nil, context)
        expect(type.resource(id: scanned_resource.id.to_s)).to be_a ScannedResource
      end
      it "can return a FileSet" do
        file_set = FactoryBot.create_for_repository(:file_set)
        type = described_class.new(nil, context)
        expect(type.resource(id: file_set.id.to_s)).to be_a FileSet
      end
    end
  end

  describe "#resources_by_bibid" do
    subject { described_class.fields["resourcesByBibid"] }
    it { is_expected.to accept_arguments(bibId: "String!") }
    context "when a user can read the resource" do
      before do
        allow(ability).to receive(:can?).with(:read, anything).and_return(true)
      end
      it "can return a resource by its bibid" do
        stub_bibdata(bib_id: "7214786")
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786").map(&:id)).to eq [scanned_resource.id]
      end
    end
    context "when the user can't read the resource" do
      before do
        allow(ability).to receive(:can?).with(:read, anything).and_return(false)
      end
      it "returns nothing" do
        stub_bibdata(bib_id: "7214786")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "7214786")
        type = described_class.new(nil, context)
        expect(type.resources_by_bibid(bib_id: "7214786")).to eq []
      end
    end
  end

  context "when the user cannot read the resource" do
    before do
      allow(ability).to receive(:can?).with(:read, anything).and_return(false)
    end

    it "returns nothing" do
      scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
      type = described_class.new(nil, context)
      expect(type.resource(id: scanned_resource.id.to_s)).to be_nil
    end
  end
end
