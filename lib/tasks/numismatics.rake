# frozen_string_literal: true

require "csv"

namespace :numismatics do
  namespace :report do
    desc "generates a report for coins which do not have any images attached"
    task coins_without_members: :environment do
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

    desc "generates a csv of coins that have not been labeled obverse / reverse"
    task coins_to_label: :environment do
      metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      query_service = metadata_adapter.query_service
      CSV.open(Rails.root.join("tmp", "numismatic_coins_to_label.csv"), "wb") do |csv|
        coins_without_members = query_service.custom_queries.find_resources_without_members(model: Numismatics::Coin)
        coins = query_service.find_all_of_model(model: Numismatics::Coin)
        coins_with_members = coins - coins_without_members
        headers = ["coin_id", "coin_number", "labels"]
        csv << headers
        coins_with_members.to_a.each do |coin|
          labels = Wayfinder.for(coin).decorated_members.map { |fs| fs.title.first }
          unless labels.include?("Obverse") || labels.include?("Reverse")
            row = [coin.id.to_s, coin.coin_number, labels.join(";")]
            csv << row
          end
        end
      end
    end
  end
end
