# frozen_string_literal: true
require "rails_helper"

RSpec.describe ExportFilesJob do
  describe ".perform" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, title: "export me", files: [file]) }
    let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
    let(:export_path) { Figgy.config["export_base"] }

    before do
      FileUtils.rm_rf(export_path) if File.exist?(export_path)
    end

    it "exports the object to disk" do
      described_class.perform_now(resource.id)
      expect(File.exist?("#{export_path}/export me/abstract.tiff")).to be true
    end
  end
end
