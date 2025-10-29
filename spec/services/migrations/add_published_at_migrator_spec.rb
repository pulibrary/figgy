# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::AddPublishedAtMigrator do
  describe ".call" do
    context "when given complete resources without published_at time stamps" do
      it "adds a published_at value" do
        stub_ezid
        ef = FactoryBot.create_for_repository(:complete_ephemera_folder)
        sm = FactoryBot.create_for_repository(:complete_scanned_map)
        sr = FactoryBot.create_for_repository(:complete_scanned_resource, identifier: "123456")

        described_class.call

        [ef, sm, sr].each do |r|
          reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: r.id)
          expect(reloaded.published_at).not_to be_blank
        end
      end

      context "when a resource is not published" do
        it "does not write a published_at value" do
          ef = FactoryBot.create_for_repository(:ephemera_folder)
          sm = FactoryBot.create_for_repository(:scanned_map)
          sr = FactoryBot.create_for_repository(:scanned_resource)

          described_class.call

          [ef, sm, sr].each do |r|
            reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: r.id)
            expect(reloaded.published_at).to be_blank
          end
        end
      end

      context "when given resources that do not have a published_at value" do
        it "does not error" do
          FactoryBot.create_for_repository(:simple_resource, state: "complete")
          FactoryBot.create_for_repository(:complete_vector_resource)
          FactoryBot.create_for_repository(:complete_raster_resource)

          described_class.call
        end
      end
    end
  end
end
