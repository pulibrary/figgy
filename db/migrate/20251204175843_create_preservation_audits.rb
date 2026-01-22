class CreatePreservationAudits < ActiveRecord::Migration[7.2]
  def change
    create_table :preservation_audits do |t|
      t.string :status
      t.string :extent
      t.string :batch_id
      t.belongs_to :ids_from, foreign_key: { to_table: :preservation_audits }

      t.timestamps
    end
  end
end
