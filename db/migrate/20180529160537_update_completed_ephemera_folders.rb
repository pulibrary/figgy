# frozen_string_literal: true
class UpdateCompletedEphemeraFolders < ActiveRecord::Migration[5.1]
  # Perform the one-way migration for updating EphemeraFolders
  def change
    EphemeraFolderMigrator.call
  end
end
