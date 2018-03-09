# frozen_string_literal: true
class MigrateToValkyrie1 < ActiveRecord::Migration[5.1]
  def up
    Valkyrie1Migrator.call
  end

  def down
    Valkyrie1Migrator.call
  end
end
