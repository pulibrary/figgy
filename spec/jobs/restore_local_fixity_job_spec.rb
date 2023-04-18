# frozen_string_literal: true
require "rails_helper"

RSpec.describe RestoreLocalFixityJob do
  it "kicks off the service" do
    allow(RestoreLocalFixity).to receive(:run)
    file_set = FactoryBot.create_for_repository(:file_set)
    described_class.perform_now(file_set.id)
    expect(RestoreLocalFixity).to have_received(:run).with(file_set)
  end
end
