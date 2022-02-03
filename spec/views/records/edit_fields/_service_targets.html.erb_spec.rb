# frozen_string_literal: true
require "rails_helper"

RSpec.describe "records/edit_fields/_service_targets.html.erb" do
  def simple_form_helper_for(change_set)
    form = nil
    view.simple_form_for(change_set) do |f|
      form = f
    end
    form
  end

  it "renders a collection on service targets" do
    file_set = ChangeSet.for(FactoryBot.build(:geo_raster_cloud_file))
    render partial: "records/edit_fields/service_targets", locals: { f: simple_form_helper_for(file_set), key: :service_targets }

    expect(rendered).to have_select("Service targets", options: ["tiles", ""])
  end
end
