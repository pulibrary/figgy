# frozen_string_literal: true
namespace :numismatics do
  namespace :missing_coins do
    desc "generates a report for coins which do not have any images attached"
    task run: :environment do

      coins_without_members = query_service.find_by_property(property: :member_ids, value: [])
      headers = ['coin_id', 'coin_number', 'issue_id', 'issue_number']
      coins_without_members.to_a.each do |coin|
        issue = coin.decorated_parent
        row = [coin.id.to_s, coin.coin_number, issue.id.to_s, issue.issue_number]
      end

    end
  end

  delegate query_service, to: :metadata_adapter

  def metadata_adapter
    Valkyrie.config.metadata_adapter
  end
end
