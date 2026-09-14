require "rails_helper"

describe PulmapIndexJob do
  let(:indexer) { instance_double(PulmapIndexer, index: true) }
  let(:document) { { layer_slug_s: "princeton-abc123" }.to_json }

  before do
    allow(PulmapIndexer).to receive(:new).and_return(indexer)
  end

  describe "#perform" do
    it "indexes the document into pulmap" do
      described_class.perform_now(document: document)

      expect(indexer).to have_received(:index).with(document: document, commit: true)
    end

    context "when called without a commit" do
      it "passes the flag through to the indexer" do
        described_class.perform_now(document: document, commit: false)

        expect(indexer).to have_received(:index).with(document: document, commit: false)
      end
    end
  end
end
