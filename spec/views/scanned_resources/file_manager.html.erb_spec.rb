# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "valhalla/base/file_manager.html.erb", type: :view do
  let(:members) { [member] }
  let(:member) { FileSetChangeSet.new(FactoryGirl.create_for_repository(:file_set)) }
  let(:parent) { ScannedResourceChangeSet.new(FactoryGirl.create_for_repository(:scanned_resource, member_ids: member.id, title: "Test title")) }

  before do
    assign(:change_set, parent)
    assign(:children, members)
    render
  end

  it "has a bulk edit header" do
    expect(rendered).to include "<h1>File Manager</h1>"
  end

  it "displays each file set's title" do
    expect(rendered).to have_selector "input[name='file_set[title][]'][type='text'][value='#{member.title.first}']"
  end

  it "has a link to edit each file set" do
    expect(rendered).to have_selector("a[href=\"#{Valhalla::ContextualPath.new(child: member, parent_id: parent.id).show}\"]")
  end

  it "has a link back to parent" do
    expect(rendered).to have_link "Test title", href: "/catalog/id-#{CGI.escape(parent.id.to_s)}"
  end

  it "renders a form for each member" do
    expect(rendered).to have_selector("#sortable form", count: members.length)
  end

  it "renders a resource form for the entire resource" do
    expect(rendered).to have_selector("form#resource-form")
  end
end
