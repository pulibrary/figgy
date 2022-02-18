# frozen_string_literal: true

require "rails_helper"

RSpec.describe "fixity_dashboard/_fixity_table" do
  context "with an orphaned file set" do
    let(:file_set) { FactoryBot.create_for_repository(:file_set, title: "Page 1") }
    let(:original_file) { instance_double FileMetadata }

    before do
      allow(file_set).to receive(:original_file).and_return(original_file)
      allow(original_file).to receive(:fixity_success).and_return(nil)
      allow(original_file).to receive(:fixity_last_success_date).and_return(nil)
      render partial: "fixity_table", locals: {resources: [file_set.decorate]}
    end

    it "links to file set without parent" do
      expect(rendered).to have_link "Page 1"
    end
  end
end
