class AddVideoFileSetsIndex < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!
  def up
    execute <<-SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS orm_resources_video_file_sets_idx ON orm_resources (id) WHERE internal_resource = 'FileSet' AND metadata @> '{"file_metadata": [{"mime_type": ["video/mp4"]}]}'
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX CONCURRENTLY IF EXISTS orm_resources_video_file_sets_idx
    SQL
  end
end
