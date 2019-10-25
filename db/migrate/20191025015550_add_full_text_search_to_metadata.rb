class AddFullTextSearchToMetadata < ActiveRecord::Migration[5.1]
  def change
    add_index :orm_resources, "to_tsvector('english', metadata)", using: :gin
  end
end
