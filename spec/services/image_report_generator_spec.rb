# frozen_string_literal: true
require "rails_helper"

RSpec.describe ImageReportGenerator do
  context "when given a collection with a variety of resources and visibilities" do
    it "outputs a CSV with a row per collection, and a column per visibility" do
      collection = FactoryBot.create_for_repository(:collection)
      # Resource out of time frame - don't return
      member = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [FactoryBot.create_for_repository(:file_set).id], member_of_collection_ids: [collection.id])
      Timecop.travel(2021, 8, 30) do
        # 1 open resource
        member = FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [FactoryBot.create_for_repository(:file_set).id], member_of_collection_ids: [collection.id])
        # MVW - it shouldn't count volumes
        FactoryBot.create_for_repository(:complete_open_scanned_resource, member_ids: [member.id], member_of_collection_ids: [collection.id])
        # 1 private resource
        FactoryBot.create_for_repository(:complete_private_scanned_resource, member_ids: [FactoryBot.create_for_repository(:file_set).id], member_of_collection_ids: [collection.id])
        # No microfilm
        FactoryBot.create_for_repository(
          :complete_private_scanned_resource,
          member_ids: [FactoryBot.create_for_repository(:file_set).id],
          call_number: "MICROFILM",
          member_of_collection_ids: [collection.id]
        )
        # 1 reading room resource
        FactoryBot.create_for_repository(:complete_reading_room_scanned_resource, member_ids: [FactoryBot.create_for_repository(:file_set).id], member_of_collection_ids: [collection.id])
        # 2 princeton only resource
        FactoryBot.create_for_repository(:complete_campus_only_scanned_resource, member_ids: [FactoryBot.create_for_repository(:file_set).id], member_of_collection_ids: [collection.id])
        FactoryBot.create_for_repository(
          :complete_campus_only_scanned_resource,
          member_ids: [FactoryBot.create_for_repository(:file_set).id, FactoryBot.create_for_repository(:file_set).id],
          member_of_collection_ids: [collection.id]
        )
      end

      report = described_class.new(collection_ids: [collection.id], date_range: DateTime.new(2021, 7, 1)..DateTime.new(2022, 6, 30))
      report.write(path: Rails.root.join("tmp", "output.csv"))
      read = CSV.read(Rails.root.join("tmp", "output.csv"), headers: true, header_converters: :symbol)

      expect(read.length).to eq 1
      first_collection = read[0].to_h
      expect(first_collection[first_collection.keys.first]).to eq collection.title.first
      expect(first_collection[:open_titles]).to eq "1"
      expect(first_collection[:open_image_count]).to eq "1"
      expect(first_collection[:private_titles]).to eq "1"
      expect(first_collection[:private_image_count]).to eq "1"
      expect(first_collection[:reading_room_titles]).to eq "1"
      expect(first_collection[:reading_room_image_count]).to eq "1"
      expect(first_collection[:princeton_only_titles]).to eq "2"
      expect(first_collection[:princeton_only_image_count]).to eq "3"
    end
  end
end
