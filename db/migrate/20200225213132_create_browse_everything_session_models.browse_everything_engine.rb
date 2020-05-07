# This migration comes from browse_everything_engine (originally 20190905134421)
# frozen_string_literal: true

class CreateBrowseEverythingSessionModels < ActiveRecord::Migration[(Rails.version =~ /5.1/ ? 5.1 : 5.2)]
  def change
    create_table :browse_everything_session_models do |t|
      t.string :uuid
      t.text :session

      t.timestamps
    end
  end
end
