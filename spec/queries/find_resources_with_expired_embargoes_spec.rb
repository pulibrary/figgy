# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindResourcesWithExpiredEmbargoes do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_resources_with_expired_embargoes" do
    context "when a resource has an embargo date in the past" do
      it "returns the resources" do
        date = "1/1/1999"
        resource = FactoryBot.create_for_repository(:scanned_resource, embargo_date: date)
        output = query.find_resources_with_expired_embargoes
        expect(output.to_a.map(&:id)).to include(resource.id)
      end
    end

    context "when a resource has an embargo date set to the current date" do
      it "returns the resources" do
        date = Time.zone.today.strftime("%-m/%-d/%Y")
        resource = FactoryBot.create_for_repository(:scanned_resource, embargo_date: date)
        output = query.find_resources_with_expired_embargoes
        expect(output.to_a.map(&:id)).to include(resource.id)
      end
    end

    context "when a resource has an embargo date set to a future date" do
      it "returns the resources" do
        date = (Time.zone.today + 1).strftime("%-m/%-d/%Y")
        resource = FactoryBot.create_for_repository(:scanned_resource, embargo_date: date)
        output = query.find_resources_with_expired_embargoes
        expect(output.to_a.map(&:id)).not_to include(resource.id)
      end
    end
  end
end
