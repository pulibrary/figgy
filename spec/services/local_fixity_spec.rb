# frozen_string_literal: true
require "rails_helper"

RSpec.describe LocalFixity do
  with_queue_adapter :inline

  describe ".queue_daily_check!" do
    it "queues a random per-day subset given an annual percent to check" do
      resources = Array.new(10) do |_n|
        FactoryBot.create_for_repository(:file_set)
      end
      allow(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to receive(:find_random_resources_by_model).and_return([resources[0]].lazy)
      allow(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to receive(:count_all_of_model).with(model: FileSet).and_return(10_000)
      allow(Rails.logger).to receive(:info)
      allow(LocalFixityJob).to receive(:perform_later)

      LocalFixity::FixityRequestor.queue_daily_check!(annual_percent: 10)

      expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to have_received(:find_random_resources_by_model).with(limit: 3, model: FileSet)
      expect(LocalFixityJob).to have_received(:perform_later).exactly(1).times
      expect(Rails.logger).to have_received(:info).with("Enqueued 3 FileSets for Local Fixity Checking")
    end
  end
end
