# frozen_string_literal: true

require "rails_helper"

RSpec.describe "base/file_manager.html.erb", type: :view do
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, title: "Test Title", files: [file]) }
  let(:members) { [member] }
  let(:member) { FileSetChangeSet.new(Wayfinder.for(scanned_resource).members_with_parents.first) }
  let(:parent) { ScannedResourceChangeSet.new(scanned_resource) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }

  before do
    assign(:change_set, parent)
    assign(:children, members)
    stub_blacklight_views
    render
  end

  it "renders correctly" do
    expect(rendered).to include "<h1>File Manager</h1>"
    expect(rendered).to include member.title.first.to_s
    expect(rendered).to have_selector("a[href=\"#{ContextualPath.new(child: member, parent_id: parent.id).show}\"]")
    expect(rendered).to have_link "Test Title", href: "/catalog/#{parent.id}"
    expect(rendered).to have_selector(".gallery form", count: 2)
    expect(rendered).to have_selector("img[src='#{ManifestBuilder::ManifestHelper.new.manifest_image_path(member.thumbnail_id)}/full/!200,150/0/default.jpg']")
  end

  context "when the resource has a tombstone for a deleted FileSet" do
    let(:parent) do
      tombstone
      ScannedResourceChangeSet.new(scanned_resource)
    end
    let(:tombstone) do
      unpreserved_tombstone
      FactoryBot.create_for_repository(
        :tombstone,
        parent_id: scanned_resource.id,
        file_set_id: "1",
        file_set_title: "Test Title",
        file_set_original_filename: "02.tif",
        preservation_object: PreservationObject.new
      )
    end
    let(:unpreserved_tombstone) do
      FactoryBot.create_for_repository(:tombstone, parent_id: scanned_resource.id, file_set_id: "1", file_set_title: "Test Title 2", file_set_original_filename: "01.tif")
    end
    it "renders a form to reinstate it" do
      expect(rendered).to include "<h2>Deleted Files</h2>"
      expect(rendered).to include "Test Title 2 (01.tif)"
      expect(rendered).to have_selector "input[name='scanned_resource[tombstone_restore_ids][]'][value='#{tombstone.id}']", visible: false
      expect(rendered).not_to have_selector "input[name='scanned_resource[tombstone_restore_ids][]'][value='#{unpreserved_tombstone.id}']", visible: false
      expect(rendered).to have_button "Reinstate"
    end
  end

  context "when a FileSet has errors" do
    let(:original_file) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], error_message: ["errors"]) }
    let(:file_set) { FactoryBot.build(:file_set, file_metadata: [original_file]) }
    let(:member) { FileSetChangeSet.new(file_set) }

    it "displays an error message" do
      expect(rendered).to include "<span>Error generating derivatives</span>"
    end
  end
end
