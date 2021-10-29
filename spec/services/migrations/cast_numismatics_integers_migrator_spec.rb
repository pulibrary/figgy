# frozen_string_literal: true

require "rails_helper"

RSpec.describe Migrations::CastNumismaticsIntegersMigrator do
  describe ".run" do
    it "migrates number fields from strings to integers" do
      accession = FactoryBot.create_for_repository(:numismatic_accession, accession_number: 100)
      coin = FactoryBot.create_for_repository(:coin, coin_number: 200, find_number: 300)
      issue = FactoryBot.create_for_repository(:numismatic_issue, issue_number: 400, member_ids: [coin.id])

      adapter = Valkyrie::MetadataAdapter.find(:postgres)

      # save them as strings
      accession_resource = adapter.resources.where(id: accession.id.to_s)
      accession_attributes = accession_resource.first
      accession_attributes[:metadata]["accession_number"] = ["100"]
      accession_resource.returning.update(accession_attributes)

      coin_resource = adapter.resources.where(id: coin.id.to_s)
      coin_attributes = coin_resource.first
      coin_attributes[:metadata]["coin_number"] = ["200"]
      coin_attributes[:metadata]["find_number"] = ["300"]
      coin_resource.returning.update(coin_attributes)

      issue_resource = adapter.resources.where(id: issue.id.to_s)
      issue_attributes = issue_resource.first
      issue_attributes[:metadata]["issue_number"] = ["400"]
      issue_resource.returning.update(issue_attributes)

      described_class.run

      accession_attributes = adapter.resources.where(id: accession.id.to_s).first
      coin_attributes = adapter.resources.where(id: coin.id.to_s).first
      issue_attributes = adapter.resources.where(id: issue.id.to_s).first

      expect(accession_attributes[:metadata]["accession_number"]).to eq [100]
      expect(coin_attributes[:metadata]["coin_number"]).to eq [200]
      expect(coin_attributes[:metadata]["find_number"]).to eq [300]
      expect(issue_attributes[:metadata]["issue_number"]).to eq [400]
    end
  end
end
