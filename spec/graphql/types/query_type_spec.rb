# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::QueryType do
  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:resource).of_type(Types::Resource) }
    describe "resource field" do
      subject { described_class.fields["resource"] }
      it { is_expected.to accept_arguments(id: "ID!") }
      it "can return a resource by ID" do
        scanned_resource = FactoryBot.create_for_repository(:scanned_resource)
        type = described_class.new(nil, {})
        expect(type.resource(id: scanned_resource.id.to_s)).to be_a ScannedResource
      end
      it "can return a FileSet" do
        file_set = FactoryBot.create_for_repository(:file_set)
        type = described_class.new(nil, {})
        expect(type.resource(id: file_set.id.to_s)).to be_a FileSet
      end
    end
  end
end
