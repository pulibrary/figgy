# frozen_string_literal: true
namespace :export do
  desc "Imports a resource from Plum"
  task cicognara: :environment do
    coll = ENV['COLL']
    abort "usage: rake export:cicognara COLL=[collection id]" unless coll

    CSV do |csv|
      csv << CicognaraCSV.headers
      CicognaraCSV.values(coll).each do |row|
        csv << row
      end
    end
  end
end
