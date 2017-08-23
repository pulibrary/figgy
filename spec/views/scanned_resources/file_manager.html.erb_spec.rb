# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe "valhalla/base/file_manager.html.erb", type: :view do
  let(:scanned_resource) { FactoryGirl.create_for_repository(:scanned_resource, title: "Test Title", files: [file]) }
  let(:members) { [member] }
  let(:member) { FileSetChangeSet.new(Valkyrie.config.metadata_adapter.query_service.find_by(id: scanned_resource.member_ids.first)) }
  let(:parent) { ScannedResourceChangeSet.new(scanned_resource) }
  let(:file) { fixture_file_upload('files/example.tif', 'image/tiff') }

  before do
    assign(:change_set, parent)
    assign(:children, members)
    stub_blacklight_views
    render
  end

  it "renders correctly" do
    expect(rendered).to include "<h1>File Manager</h1>"
    expect(rendered).to have_selector "input[name='file_set[title][]'][type='text'][value='#{member.title.first}']"
    expect(rendered).to have_selector("a[href=\"#{Valhalla::ContextualPath.new(child: member, parent_id: parent.id).show}\"]")
    expect(rendered).to have_link "Test Title", href: "/catalog/id-#{parent.id}"
    expect(rendered).to have_selector("#sortable form", count: members.length)
    expect(rendered).to have_selector("form#resource-form")
    expect(rendered).to have_selector("input[name='file_set[viewing_hint]']")
    expect(rendered).to have_selector("img[src='#{ManifestBuilder::ManifestHelper.new.manifest_image_path(member.thumbnail_id)}/full/!200,150/0/default.jpg']")
  end
end
