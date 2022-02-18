# frozen_string_literal: true

class AddResourceIdToAuthTokens < ActiveRecord::Migration[5.1]
  def change
    add_column :auth_tokens, :resource_id, :string
  end
end
