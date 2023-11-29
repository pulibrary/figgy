# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::ResetBoxThumbnails do
  let(:query_service) { ChangeSetPersister.default.query_service }

  describe ".call" do
    context "when given an id for an ephemera box containing a folder whose thumbnail_id is set to an orphan file set" do
      it "sets a new thumbnail" do
        orphan_file_set = FactoryBot.create_for_repository(:file_set)
        file_set1 = FactoryBot.create_for_repository(:file_set)
        file_set2 = FactoryBot.create_for_repository(:file_set)
        file_set3 = FactoryBot.create_for_repository(:file_set)
        folder1 = FactoryBot.create_for_repository(:ephemera_folder, member_ids: file_set1.id, thumbnail_id: orphan_file_set.id)
        folder2 = FactoryBot.create_for_repository(:ephemera_folder, member_ids: file_set2.id, thumbnail_id: file_set2.id)
        # add one without a thumbnail
        folder3 = FactoryBot.create_for_repository(:ephemera_folder, member_ids: file_set3.id)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder1.id, folder2.id, folder3.id])

        reset = described_class.call(box_id: box.id)

        expect { query_service.find_by(id: orphan_file_set.id) }.not_to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        expect { query_service.find_by(id: file_set1.id) }.not_to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        expect { query_service.find_by(id: file_set2.id) }.not_to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
        folder1 = query_service.find_by(id: folder1.id)
        folder2 = query_service.find_by(id: folder2.id)
        expect(folder2.thumbnail_id).to eq [file_set2.id]
        expect(folder1.thumbnail_id).to eq [file_set1.id]
        expect(reset).to eq 1
      end
    end

    context "when given an id that's not an ephemera box id" do
      it "errors" do
        project = FactoryBot.create_for_repository(:ephemera_project)

        expect { described_class.call(box_id: project.id) }.to raise_error(Migrations::InvalidResourceTypeError)
      end
    end

    context "when there's no resource for the given thumbnail id" do
      it "sets an existing file set as thumbnail" do
        file_set1 = FactoryBot.create_for_repository(:file_set)
        folder1 = FactoryBot.create_for_repository(:ephemera_folder, member_ids: file_set1.id, thumbnail_id: Valkyrie::ID.new(SecureRandom.uuid))
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder1.id])

        reset = described_class.call(box_id: box.id)

        folder1 = query_service.find_by(id: folder1.id)
        expect(folder1.thumbnail_id).to eq [file_set1.id]
        expect(reset).to eq 1
      end
    end

    context "when the thumbnail resource doesn't exist and there are no members" do
      it "sets thumbnail id to empty" do
        folder1 = FactoryBot.create_for_repository(:ephemera_folder, member_ids: [], thumbnail_id: Valkyrie::ID.new(SecureRandom.uuid))
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder1.id])

        reset = described_class.call(box_id: box.id)

        folder1 = query_service.find_by(id: folder1.id)
        expect(folder1.thumbnail_id).to be_empty
        expect(reset).to eq 1
      end
    end
  end
end
