# frozen_string_literal: true
require "rails_helper"

RSpec.describe "records/edit_fields/_ocr_language.html.erb" do
  def simple_form_helper_for(change_set)
    form = nil
    view.simple_form_for(change_set) do |f|
      form = f
    end
    form
  end

  it "renders a collection on ocr language" do
    resource = ChangeSet.for(FactoryBot.build(:scanned_resource))
    render partial: "records/edit_fields/ocr_language", locals: { f: simple_form_helper_for(resource), key: :ocr_language }

    expect(rendered).to have_select("OCR Language")
    expect(rendered).to have_selector "#scanned_resource_ocr_language[multiple=multiple]"
  end
end
