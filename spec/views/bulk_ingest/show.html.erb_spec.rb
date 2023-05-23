# frozen_string_literal: true
require "rails_helper"

RSpec.describe "bulk_ingest/show.html.erb" do
  it "renders a check box to preserve file names and a select for rights statement" do
    assign :resource_class, ScannedResource
    assign :visibility, []
    assign :states, []
    assign :collections, []
    render

    expect(rendered).to have_selector "input[type='checkbox'][name='preserve_file_names'][value='1']"
    expect(rendered).to have_selector "select[name='rights_statement'] option[value='http://rightsstatements.org/vocab/CNE/1.0/']"
  end
end
