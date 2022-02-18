# frozen_string_literal: true

class EmailNotUnique < ActiveRecord::Migration[4.2]
  def change
    remove_index :users, :email
    add_index :users, :email
  end
end
