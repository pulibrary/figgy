class AddInProcessFileSetsIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  def up
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS orm_resources_in_process_file_sets_idx ON orm_resources (id) WHERE internal_resource = 'FileSet' AND metadata @> '{"processing_status": ["in process"]}'
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX CONCURRENTLY IF EXISTS orm_resources_in_process_file_sets_idx
    SQL
  end
end
