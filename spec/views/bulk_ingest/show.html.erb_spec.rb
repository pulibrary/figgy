# frozen_string_literal: true
require "rails_helper"

RSpec.describe "bulk_ingest/show.html.erb" do
  it "renders a check box to preserve file names" do
    assign :resource_class, ScannedResource
    assign :visibility, []
    assign :states, []
    assign :collections, []
    render

    expect(rendered).to have_selector "input[type='checkbox'][name='preserve_file_names'][value='1']"
  end
end
