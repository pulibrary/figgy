# frozen_string_literal: true
require "rails_helper"

RSpec.describe PreservationObjectDecorator do
  subject(:decorated) { described_class.new(resource) }

  let(:file_set) { FactoryBot.create_for_repository(:file_set) }
  let(:resource) { FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id) }

  describe "#preserved_resources" do
    it "access all preserved resources" do
      expect(decorated.preserved_resources).not_to be_empty
      expect(decorated.preserved_resources.map(&:id)).to include(file_set.id)
    end
  end

  describe "#preserved_resource" do
    it "access all preserved resources" do
      expect(decorated.preserved_resource).to be_a FileSetDecorator
      expect(decorated.preserved_resource.id).to eq file_set.id
    end
  end
end
