# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::DaoMigrator do
  include ActiveJob::TestHelper
  describe ".call" do
    it "runs the UpdateDaoJob for each resource with an archival collection code" do
      FactoryBot.create_for_repository(:scanned_resource, archival_collection_code: "AC111")
      FactoryBot.create_for_repository(:scanned_resource, archival_collection_code: "C0652")
      FactoryBot.create_for_repository(:scanned_resource)
      clear_enqueued_jobs

      described_class.call

      expect(UpdateDaoJob).to have_been_enqueued.twice
    end
  end
end
