# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shrine::Storage::VersionedGoogleCloudStorage do
  describe "#get_file" do
    it "gets the most recent versioned file" do
      # This test is very particular to the implementation. We know this works,
      # but there's no easy way to set up an accurate mock Google::Cloud::Storage, so
      # this is the best we can do - effectively just testing that it sorts in
      # memory and returns the most recent one.
      old_version = instance_double(Google::Cloud::Storage::File, updated_at: 10.minutes.ago)
      latest_version = instance_double(Google::Cloud::Storage::File, updated_at: 5.minutes.ago)
      bucket = instance_double(Google::Cloud::Storage::Bucket)
      allow(bucket).to receive(:files).with(delimiter: "/", prefix: "/all_my_files/1.json", versions: true).and_return([old_version, latest_version])
      storage = instance_double(Google::Cloud::Storage::Project, bucket: bucket)
      allow(Google::Cloud::Storage).to receive(:new).and_return(storage)

      storage = described_class.new(bucket: "my_bucket")
      output = storage.get_file("/all_my_files/1.json")

      expect(output).to eq latest_version
    end
  end
end
