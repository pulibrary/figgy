require "rails_helper"

RSpec.describe EphemeraFolderIndexer do
  describe ".to_solr" do
    context "when workflow is not yet complete" do
      it "indexes empty read group" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        output = described_class.new(resource: folder).to_solr
        expect(output["read_access_group_ssim"]).to be_empty
      end
    end

    context "when workflow is complete" do
      it "indexes read group public" do
        folder = FactoryBot.create_for_repository(:ephemera_folder, state: "complete")
        output = described_class.new(resource: folder).to_solr
        expect(output["read_access_group_ssim"]).to eq ["public"]
      end
    end

    context "when the folder has no box" do
      it "indexes the folder label" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        output = described_class.new(resource: folder).to_solr
        expect(output[:folder_label_tesim]).to eq "Folder one"
      end

      it "does not index a box id" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        output = described_class.new(resource: folder).to_solr
        expect(output.keys).not_to include :parent_box_id_ssi
      end
    end

    context "when the folder is inside a box" do
      it "indexes the box name into the folder label" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id])
        output = described_class.new(resource: folder).to_solr
        expect(output[:folder_label_tesim]).to eq "Box 1 Folder one"
      end

      it "indexes the box id" do
        folder = FactoryBot.create_for_repository(:ephemera_folder)
        box = FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id])
        output = described_class.new(resource: folder).to_solr
        expect(output[:parent_box_id_ssi]).to eq box.id.to_s
      end
    end
  end
end
