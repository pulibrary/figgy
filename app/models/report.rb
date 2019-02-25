# frozen_string_literal: true
class Report
  def self.all
    [:ead_to_marc, :ephemera_data, :identifiers_to_reconcile, :pulfa_ark_report]
  end
end
