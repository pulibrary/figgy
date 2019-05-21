# frozen_string_literal: true
require "rails_helper"

RSpec.describe SourceMetadataIdentifierMigrator do
  before do
    class MyResource < Valkyrie::Resource
      attribute :source_metadata_identifier
    end
  end

  after do
    Object.send(:remove_const, :MyResource)
  end

  describe ".call" do
    it "changes slashes to underscores in source_metadata_identifiers" do
      # create record with a slash in its source_metadata_identifier
      adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      resource = adapter.persister.save(resource: MyResource.new(source_metadata_identifier: "C0652/c0377"))

      # run the migrator
      described_class.call

      # verify that the slash has been changed to an underscore
      migrated = adapter.query_service.find_by(id: resource.id)
      expect(migrated.source_metadata_identifier).to eq(["C0652_c0377"])
    end
  end
end
