require "rails_helper"

describe PulmapDeleteJob do
  let(:indexer) { instance_double(PulmapIndexer, delete: true) }

  before do
    allow(PulmapIndexer).to receive(:new).and_return(indexer)
  end

  describe "#perform" do
    it "deletes the document from pulmap" do
      described_class.perform_now(slug: "princeton-abc123")

      expect(indexer).to have_received(:delete).with(slug: "princeton-abc123", commit: true)
    end

    context "when called without a commit" do
      it "passes the flag through to the indexer" do
        described_class.perform_now(slug: "princeton-abc123", commit: false)

        expect(indexer).to have_received(:delete).with(slug: "princeton-abc123", commit: false)
      end
    end
  end
end
