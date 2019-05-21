# frozen_string_literal: true
class UpdateSourceMetadataIdentifier < ActiveRecord::Migration[5.1]
  def change
    SourceMetadataIdentifierMigrator.call
  end
end
