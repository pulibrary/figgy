# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::LoanChangeSet do
  subject(:change_set) { described_class.new(loan) }
  let(:loan) { Numismatics::Loan.new }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:firm_id, :person_id, :date_in, :date_out, :exhibit_name, :note, :type)
    end
  end
end
