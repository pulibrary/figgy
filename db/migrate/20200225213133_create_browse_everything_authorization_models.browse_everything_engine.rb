# This migration comes from browse_everything_engine (originally 20190911121009)
# frozen_string_literal: true

class CreateBrowseEverythingAuthorizationModels < ActiveRecord::Migration[(/5.1/.match?(Rails.version) ? 5.1 : 5.2)]
  def change
    create_table :browse_everything_authorization_models do |t|
      t.string :uuid
      t.text :authorization

      t.timestamps
    end
  end
end
