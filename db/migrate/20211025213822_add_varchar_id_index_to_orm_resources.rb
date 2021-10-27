# frozen_string_literal: true

class AddVarcharIdIndexToOrmResources < ActiveRecord::Migration[5.2]
  def change
    add_index :orm_resources, "(id::varchar)"
  end
end
