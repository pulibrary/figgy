# frozen_string_literal: true
require "rails_helper"

RSpec.describe "base/file_manager.html.erb", type: :view do
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, title: "Test Title", files: [file]) }
  let(:members) { [member] }
  let(:member) { FileSetChangeSet.new(Wayfinder.for(scanned_resource).members_with_parents.first) }
  let(:parent) { ScannedResourceChangeSet.new(scanned_resource) }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:event) {}

  before do
    stub_ezid
    assign(:change_set, parent)
    assign(:children, members)
    event
    stub_blacklight_views
    allow(view).to receive(:controller_name).and_return("catalog")
    render
  end

  it "renders correctly" do
    expect(rendered).to include "<h1>File Manager</h1>"
    expect(rendered).to include member.title.first.to_s
    expect(rendered).to have_selector("a[href=\"#{ContextualPath.new(child: member, parent_id: parent.id).show}\"]")
    expect(rendered).to have_link "Test Title", href: "/catalog/#{parent.id}"
    expect(rendered).to have_selector(".gallery form", count: 1)
    expect(rendered).to have_selector("img[src='#{ManifestBuilder::ManifestHelper.new.manifest_image_path(member.thumbnail_id)}/full/!200,150/0/default.jpg']")
  end

  context "when the resource has a deletion_marker for a deleted FileSet" do
    let(:parent) do
      deletion_marker
      ScannedResourceChangeSet.new(scanned_resource)
    end
    let(:resource_id) { Valkyrie::ID.new(SecureRandom.uuid) }
    let(:deletion_marker) do
      unpreserved_deletion_marker
      FactoryBot.create_for_repository(
        :deletion_marker,
        parent_id: scanned_resource.id,
        resource_id: resource_id,
        resource_title: "Test Title",
        original_filename: "02.tif",
        preservation_object: PreservationObject.new
      )
    end
    let(:unpreserved_deletion_marker) do
      FactoryBot.create_for_repository(:deletion_marker, parent_id: scanned_resource.id, resource_id: resource_id, resource_title: "Test Title 2", original_filename: "01.tif")
    end
    it "renders a form to reinstate it" do
      expect(rendered).to include "<h2>Deleted Files</h2>"
      expect(rendered).to include "Test Title 2 (01.tif)"
      expect(rendered).to have_selector "input[name='scanned_resource[deletion_marker_restore_ids][]'][value='#{deletion_marker.id}']", visible: false
      expect(rendered).not_to have_selector "input[name='scanned_resource[deletion_marker_restore_ids][]'][value='#{unpreserved_deletion_marker.id}']", visible: false
      expect(rendered).to have_button "Reinstate"
      expect(rendered).not_to include "Local Fixity Failed"
    end
  end

  context "when a FileSet has Derivative errors" do
    let(:original_file) { FileMetadata.new(use: [Valkyrie::Vocab::PCDMUse.OriginalFile], error_message: ["errors"]) }
    let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [original_file]) }
    let(:member) { FileSetChangeSet.new(file_set) }

    it "displays an error message" do
      expect(rendered).to include "Derivatives Failed"
    end
  end

  context "when a FileSet has Local Fixity Errors" do
    let(:event) { FactoryBot.create(:local_fixity_failure, resource_id: member.id) }

    it "displays a local fixity error message" do
      expect(rendered).to include "Local Fixity Failed"
    end
  end

  context "when a FileSet is a video and is missing captions" do
    let(:file_set) { FactoryBot.create_for_repository(:video_file_set) }
    let(:member) { FileSetChangeSet.new(file_set) }
    it "renders an error" do
      expect(rendered).to have_link "Attach Missing Captions"
    end
  end

  context "when a FileSet has Cloud Fixity Errors" do
    with_queue_adapter :inline
    let(:event) { FactoryBot.create(:cloud_fixity_failure, resource_id: Wayfinder.for(member).preservation_object.id, child_id: member.resource.primary_file.id) }

    it "displays a cloud fixity error message" do
      expect(rendered).to include "Cloud Fixity Failed"
    end
  end
end
