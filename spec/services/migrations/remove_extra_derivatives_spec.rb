# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::RemoveExtraDerivatives do
  include ActiveJob::TestHelper
  with_queue_adapter :test
  describe ".call" do
    it "enqueues a regenerate derivatives job for file sets with extra thumnbnails" do
      clear_enqueued_jobs
      file_set = FactoryBot.create_for_repository(
        :file_set,
        file_metadata: [FactoryBot.build(:image_thumbnail),
                        FactoryBot.build(:image_thumbnail),
                        FactoryBot.build(:image_original)]
      )
      file_set2 = FactoryBot.create_for_repository(
        :file_set,
        file_metadata: [FactoryBot.build(:image_thumbnail),
                        FactoryBot.build(:image_thumbnail),
                        FactoryBot.build(:image_original)]
      )
      file_set3 = FactoryBot.create_for_repository(
        :file_set,
        file_metadata: [FactoryBot.build(:image_derivative),
                        FactoryBot.build(:image_thumbnail),
                        FactoryBot.build(:image_original)]
      )
      FactoryBot.create_for_repository(:raster_resource, member_ids: [file_set.id, file_set2.id, file_set3.id])

      described_class.call
      expect(RegenerateDerivativesJob).to have_been_enqueued.twice
      expect(RegenerateDerivativesJob).to have_been_enqueued.with(file_set.id.to_s)
      expect(RegenerateDerivativesJob).to have_been_enqueued.with(file_set2.id.to_s)
      expect(RegenerateDerivativesJob).not_to have_been_enqueued.with(file_set3.id.to_s)
    end
  end
end
