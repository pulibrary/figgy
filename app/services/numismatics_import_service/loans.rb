# frozen_string_literal: true

# Data access object for loans in numismatics database
class NumismaticsImportService::Loans
  attr_reader :db_adapter
  def initialize(db_adapter:)
    @db_adapter = db_adapter
  end

  def coin_query(coin_id:)
    <<-SQL
      SELECT *
      FROM Loans
      LEFT OUTER JOIN LoanTypes ON Loans.LoanTypeID = LoanTypes.LoanTypeId
      WHERE CoinID = '#{coin_id}'
    SQL
  end

  def attributes_by_coin(coin_id:)
    records = db_adapter.execute(query: coin_query(coin_id: coin_id))

    records.map do |record|
      OpenStruct.new(
        firm_id: record["LoanFirmID"].to_s,
        person_id: record["LoanPersonID"].to_s,
        date_in: record["DateIn"],
        date_out: record["DateOut"],
        exhibit_name: record["ExhibitName"],
        note: record["Note"],
        type: record["LoanType"]
      )
    end
  end
end
