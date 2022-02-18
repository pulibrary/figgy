# frozen_string_literal: true

# Migration for migrating from Valkyrie 0.x releases to 1.0
# Please note that this approach should not be undertaken for future migrations
class MigrateToValkyrie1 < ActiveRecord::Migration[5.1]
  def up
    Valkyrie1Migrator.call
  end

  def down
    Valkyrie1Migrator.call
  end
end
