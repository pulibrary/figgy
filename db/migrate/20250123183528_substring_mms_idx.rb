class SubstringMmsIdx < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!
  def up
    execute <<-SQL
      CREATE INDEX CONCURRENTLY mms_id_substring_idx ON orm_resources (SUBSTRING(metadata->'source_metadata_identifier'->>0,1,2)) WHERE (("internal_resource" NOT IN ('FileSet', 'PreservationObject', 'DeletionMarker', 'Event', 'EphemeraTerm')))
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX CONCURRENTLY mms_id_substring_idx
    SQL
  end
end
