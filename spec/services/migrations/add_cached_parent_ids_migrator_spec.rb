# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::AddCachedParentIdsMigrator do
  describe ".call" do
    context "when given objects without cached parent ids" do
      it "adds the cached parent id" do
        child_file_set = FactoryBot.create_for_repository(:file_set)
        child_sr = FactoryBot.create_for_repository(:scanned_resource, member_ids: child_file_set.id)
        FactoryBot.create_for_repository(:scanned_resource, member_ids: child_sr.id)

        child_sm = FactoryBot.create_for_repository(:scanned_map)
        FactoryBot.create_for_repository(:scanned_map, member_ids: child_sm.id)

        ephemera_folder = FactoryBot.create_for_repository(:ephemera_folder)
        ephemera_box = FactoryBot.create_for_repository(:ephemera_box, member_ids: ephemera_folder.id)
        FactoryBot.create_for_repository(:ephemera_project, member_ids: ephemera_box.id)

        child_vr = FactoryBot.create_for_repository(:vector_resource)
        FactoryBot.create_for_repository(:vector_resource, member_ids: child_vr.id)

        child_rr = FactoryBot.create_for_repository(:raster_resource)
        FactoryBot.create_for_repository(:raster_resource, member_ids: child_rr.id)

        pre_cached_child = FactoryBot.create_for_repository(:scanned_resource, cached_parent_id: SecureRandom.uuid)

        described_class.call

        [child_sr, child_sm, ephemera_box, ephemera_folder, child_vr, child_rr].each do |child|
          reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: child.id)
          expect(reloaded.cached_parent_id).not_to be_blank
        end
        expect(child_file_set.cached_parent_id).to be_blank
        reloaded = Valkyrie.config.metadata_adapter.query_service.find_by(id: pre_cached_child.id)
        # Ensure the migrator doesn't touch things that already have a cached
        # ID.
        expect(reloaded.cached_parent_id).to eq pre_cached_child.cached_parent_id
      end
    end
  end
end
