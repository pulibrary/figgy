# frozen_string_literal: true
require 'rails_helper'
include ActionDispatch::TestProcess

RSpec.describe "valhalla/base/order_manager.html.erb", type: :view do
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
    expect(rendered).to include "<div id=\"order-manager\" data-class-name=\"#{parent.model_name.plural}\" data-resource=\"#{parent.id}\"></div>"
  end
  context "when given a MVW" do
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, title: "Test Title", member_ids: [child.id]) }
    let(:child) { FactoryBot.create_for_repository(:scanned_resource, title: "Child Title") }
    let(:member) { DynamicChangeSet.new(child) }
    let(:parent) { scanned_resource && member }
    let(:members) { [] }
    it "renders a breadcrumb for the parent" do
      expect(rendered).to have_selector "li a[href='/catalog/#{child.id}']", text: "Child Title"
      expect(rendered).to have_selector "li a[href='/catalog/#{scanned_resource.id}']", text: "Test Title"
    end
  end
end
