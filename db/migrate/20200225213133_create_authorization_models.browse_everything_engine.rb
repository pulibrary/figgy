# This migration comes from browse_everything_engine (originally 20190911121009)
# frozen_string_literal: true

class CreateAuthorizationModels < ActiveRecord::Migration[(Rails.version =~ /5.1/ ? 5.1 : 5.2)]
  def change
    create_table :authorization_models do |t|
      t.string :uuid
      t.text :authorization

      t.timestamps
    end
  end
end
