# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrowseEverything::Provider::FastFileSystem do
  describe "#name" do
    it "is File System" do
      expect(described_class.new.name).to eq "File System"
    end
  end
end
