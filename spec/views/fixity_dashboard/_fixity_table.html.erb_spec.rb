# frozen_string_literal: true
require "rails_helper"

RSpec.describe "fixity_dashboard/_fixity_table" do
  context "with an orphaned file set" do
    let(:file_set) { FactoryBot.create_for_repository(:file_set, title: "Page 1") }
    let(:local_fixity_event) do
      FactoryBot.create_for_repository(:local_fixity_success, resource_id: file_set.id, current: true)
    end
    let(:original_file) { instance_double FileMetadata }

    it "links to file set without parent" do
      render partial: "fixity_table", locals: { resources: [local_fixity_event.decorate] }
      expect(rendered).to have_link "Page 1"
    end

    context "when an event has no resource_id" do
      it "notifies Honeybadger and doesn't show that one" do
        event = FactoryBot.create_for_repository(:cloud_fixity_event, current: true)
        allow(Honeybadger).to receive(:notify)
        expect { render partial: "fixity_table", locals: { resources: [event.decorate] } }.not_to raise_error
        expect(Honeybadger).to have_received(:notify).with("Event #{event.id} has no resource_id")
      end
    end
  end
end
