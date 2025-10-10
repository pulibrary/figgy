# frozen_string_literal: true
class CreateNomismaDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :nomisma_documents do |t|
      t.string :state
      t.text :rdf

      t.timestamps
    end
  end
end
