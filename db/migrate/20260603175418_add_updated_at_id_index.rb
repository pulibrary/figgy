class AddUpdatedAtIdIndex < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def change
    add_index :orm_resources, [:updated_at, :id], algorithm: :concurrently
  end
end
