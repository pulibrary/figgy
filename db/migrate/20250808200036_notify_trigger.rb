# frozen_string_literal: true
class NotifyTrigger < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
CREATE OR REPLACE FUNCTION notify_on_orm_resource_change() RETURNS trigger AS $$
BEGIN
PERFORM pg_notify('orm_resources_change', (NEW.id)::text);
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER notify_after_orm_resource_change
AFTER INSERT OR UPDATE OR DELETE ON orm_resources
FOR EACH ROW
EXECUTE FUNCTION notify_on_orm_resource_change();
SQL
  end

  def down
    execute <<~SQL
DROP TRIGGER IF EXISTS notify_after_orm_resource_change ON orm_resources;
DROP FUNCTION IF EXISTS notify_on_orm_resource_change();
SQL
  end
end
