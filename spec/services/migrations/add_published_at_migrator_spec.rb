require "rails_helper"

RSpec.describe Migrations::AddPublishedAtMigrator do
  describe ".call" do
    context "when given complete resources without published_at time stamps" do
      it "adds a published_at value" do
        stub_ezid
        ef = FactoryBot.create_for_repository(:complete_ephemera_folder)
        sm = FactoryBot.create_for_repository(:complete_scanned_map)
        sr = FactoryBot.create_for_repository(:complete_scanned_resource, identifier: "123456")
        vr = FactoryBot.create_for_repository(:complete_vector_resource)
        rr = FactoryBot.create_for_repository(:complete_raster_resource)
        coin = FactoryBot.create_for_repository(:complete_open_coin)
        playlist = FactoryBot.create_for_repository(:complete_playlist)
        simple = FactoryBot.create_for_repository(:simple_resource, state: "complete")

        described_class.call

        [ef, sm, sr, vr, rr, coin, playlist, simple].each do |r|
          reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: r.id)
          expect(reloaded.published_at).not_to be_blank
        end
      end

      context "when a resource is not published" do
        it "does not write a published_at value" do
          ef = FactoryBot.create_for_repository(:ephemera_folder)
          sm = FactoryBot.create_for_repository(:scanned_map)
          sr = FactoryBot.create_for_repository(:scanned_resource)
          vr = FactoryBot.create_for_repository(:vector_resource)
          rr = FactoryBot.create_for_repository(:raster_resource)
          coin = FactoryBot.create_for_repository(:coin)
          playlist = FactoryBot.create_for_repository(:playlist)
          simple = FactoryBot.create_for_repository(:simple_resource)

          described_class.call

          [ef, sm, sr, vr, rr, coin, playlist, simple].each do |r|
            reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: r.id)
            expect(reloaded.published_at).to be_blank
          end
        end
      end

      context "when updating a resource raises an error" do
        it "the migrator rescues and completes without error" do
          FactoryBot.create_for_repository(:complete_scanned_resource, identifier: "123456")
          allow(ChangeSet).to receive(:for).and_raise("Error")

          expect { described_class.call }.not_to raise_error
        end
      end
    end
  end
end
