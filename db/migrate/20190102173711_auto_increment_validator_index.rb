# frozen_string_literal: true

class AutoIncrementValidatorIndex < ActiveRecord::Migration[5.1]
  def change
    [:find_number, :issue_number, :coin_number, :accession_number].each do |property|
      add_index :orm_resources, "(metadata->'#{property}'->0)", name: "orm_resources_first_#{property}_idx"
    end
  end
end
