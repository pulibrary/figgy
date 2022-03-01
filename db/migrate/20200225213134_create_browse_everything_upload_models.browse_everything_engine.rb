# This migration comes from browse_everything_engine (originally 20190930132547)
# frozen_string_literal: true

class CreateBrowseEverythingUploadModels < ActiveRecord::Migration[(/5.1/.match?(Rails.version) ? 5.1 : 5.2)]
  def change
    create_table :browse_everything_upload_models do |t|
      t.string :uuid
      t.text :upload

      t.timestamps
    end
  end
end
