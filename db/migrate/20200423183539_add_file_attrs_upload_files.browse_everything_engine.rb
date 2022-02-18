# frozen_string_literal: true

# This migration comes from browse_everything_engine (originally 20200423125901)

class AddFileAttrsUploadFiles < ActiveRecord::Migration[(/5.1/.match?(Rails.version) ? 5.1 : 5.2)]
  def change
    change_table :browse_everything_upload_files do |t|
      t.string :file_path
      t.string :file_name
      t.string :file_content_type
    end
  end
end
