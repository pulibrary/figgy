# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe "valhalla/base/file_manager.html.erb", type: :view do
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, title: "Test Title", files: [file]) }
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
    expect(rendered).to include "<div id=\"filemanager\" data-class-name=\"#{parent.model_name.plural}\" data-resource=\"#{parent.id}\"/>"
  end
end
