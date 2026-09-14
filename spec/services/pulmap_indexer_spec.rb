require "rails_helper"

RSpec.describe PulmapIndexer do
  subject(:indexer) { described_class.new }
  let(:connection) { instance_double(RSolr::Client, update: true, delete_by_query: true, commit: true) }
  let(:document) { { layer_slug_s: "princeton-abc123", dc_title_s: "Test Map" }.to_json }

  before do
    allow(RSolr).to receive(:connect).and_return(connection)
  end

  describe "#index" do
    it "adds the document and commits" do
      indexer.index(document: document)

      expect(connection).to have_received(:update).with(
        params: { overwrite: true },
        data: "[#{document}]",
        headers: { "Content-Type" => "application/json" }
      )
      expect(connection).to have_received(:commit)
    end

    context "when the update is done in bulk" do
      it "does not commit" do
        indexer.index(document: document, commit: false)

        expect(connection).to have_received(:update)
        expect(connection).not_to have_received(:commit)
      end
    end
  end

  describe "#delete" do
    it "deletes by slug and commits" do
      indexer.delete(slug: "princeton-abc123")

      expect(connection).to have_received(:delete_by_query).with("layer_slug_s:princeton\\-abc123")
      expect(connection).to have_received(:commit)
    end

    context "when the delete is done in bulk" do
      it "does not commit" do
        indexer.delete(slug: "princeton-abc123", commit: false)

        expect(connection).to have_received(:delete_by_query)
        expect(connection).not_to have_received(:commit)
      end
    end
  end
end
