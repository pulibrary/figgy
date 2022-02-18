# frozen_string_literal: true

require "rails_helper"

RSpec.describe "records/edit_fields/_contributor_uids.html.erb" do
  def simple_form_helper_for(change_set)
    form = nil
    view.simple_form_for(change_set) do |f|
      form = f
    end
    form
  end

  it "renders a collection of users" do
    user = FactoryBot.create(:user)
    project = ChangeSet.for(FactoryBot.build(:ephemera_project)).prepopulate!
    render partial: "records/edit_fields/contributor_uids", locals: {f: simple_form_helper_for(project), key: :contributor_uids}

    expect(rendered).to have_select("External Depositors", options: [user.uid, ""])
  end
end
