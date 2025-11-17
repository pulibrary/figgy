# frozen_string_literal: true
class DeleteOldTables < ActiveRecord::Migration[7.1]
  def up
    drop_table "browse_everything_authorization_models"
    drop_table "browse_everything_session_models"
    drop_table "browse_everything_upload_files"
    drop_table "browse_everything_upload_models"
    drop_table "delayed_jobs"
  end

  def down; end
end
