class CreateOcrRequests < ActiveRecord::Migration[5.2]
  def change
    create_table :ocr_requests do |t|
      t.string :filename
      t.string :state
      t.text :note
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
