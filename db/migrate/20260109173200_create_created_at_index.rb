# frozen_string_literal: true
class CreateCreatedAtIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :orm_resources, :created_at
  end
end
