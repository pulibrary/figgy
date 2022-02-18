# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ParentIssueIndexer do
  it_behaves_like "a Valkyrie::Persistence::Solr::Indexer"
  describe "#to_solr" do
    context "when given a not-coin" do
      it "returns an empty hash" do
        indexer = described_class.new(resource: ScannedResource.new)

        expect(indexer.to_solr).to eq({})
      end
    end
    context "when given a resource without parents" do
      it "returns an empty hash" do
        coin = FactoryBot.create_for_repository(:coin)
        indexer = described_class.new(resource: coin)

        expect(indexer.to_solr).to eq({})
      end
    end
    context "when given a coin with an issue" do
      it "returns issue properties" do
        coin = FactoryBot.create_for_repository(:coin)
        FactoryBot.create_for_repository(:numismatic_issue, member_ids: coin.id)
        indexer = described_class.new(resource: coin)

        expect(indexer.to_solr).to eq(
          "issue_denomination_tesim" => ["$1"],
          "issue_downloadable_tesim" => ["public"],
          "issue_issue_number_tesim" => ["1"],
          "issue_rights_statement_tesim" => [RightsStatements.no_known_copyright]
        )
      end
    end
  end
end
