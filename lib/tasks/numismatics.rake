# frozen_string_literal: true

require "csv"

namespace :numismatics do
  namespace :report_coins_without_members do
    desc "generates a report for coins which do not have any images attached"
    task run: :environment do
      metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      query_service = metadata_adapter.query_service
      CSV.open(Rails.root.join("tmp", "numismatic_coins_without_members.csv"), "wb") do |csv|
        coins_without_members = query_service.custom_queries.find_resources_without_members(model: Numismatics::Coin)
        headers = ["coin_id", "coin_number", "issue_id", "issue_number"]
        csv << headers
        coins_without_members.to_a.each do |coin|
          issue = coin.decorate.parents.first
          row = [coin.id.to_s, coin.coin_number, issue.id.to_s, issue.issue_number]
          csv << row
        end
      end
    end
  end
end
