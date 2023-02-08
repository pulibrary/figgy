# frozen_string_literal: true
require "rails_helper"

RSpec.describe "fixity_dashboard/_fixity_table" do
  context "with an orphaned file set" do
    let(:file_set) { FactoryBot.create_for_repository(:file_set, title: "Page 1") }
    let(:local_fixity_event) do
      FactoryBot.create_for_repository(:local_fixity_success, resource_id: file_set.id, current: true)
    end
    let(:original_file) { instance_double FileMetadata }

    before do
      render partial: "fixity_table", locals: { resources: [local_fixity_event.decorate] }
    end

    it "links to file set without parent" do
      expect(rendered).to have_link "Page 1"
    end
  end
end
