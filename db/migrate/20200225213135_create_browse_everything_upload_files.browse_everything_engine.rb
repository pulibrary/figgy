# This migration comes from browse_everything_engine (originally 20191004125901)
# frozen_string_literal: true

class CreateBrowseEverythingUploadFiles < ActiveRecord::Migration[(/5.1/.match?(Rails.version) ? 5.1 : 5.2)]
  def change
    create_table :browse_everything_upload_files do |t|
      t.string :container_id
      t.string :name

      t.timestamps
    end
  end
end
