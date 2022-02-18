# frozen_string_literal: true

# This migration creates a couple functions to map nested Valkyrie::IDs that are
# stored in the database to a flat array. These functions are then indexed when
# they're used so we can do some queries faster, especially
# PlaylistsFromRecording.
#
# Function definition adapted from
# https://dba.stackexchange.com/questions/212595/transform-map-json-object-array-to-primitive-for-gin-indexing
class IndexHelperFunction < ActiveRecord::Migration[5.1]
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION public.get_ids(jsonb, text)
       RETURNS jsonb
       LANGUAGE sql
       IMMUTABLE
      AS $function$
      select jsonb_agg(x) from
         (select jsonb_array_elements($1->$2)->>'id') as f(x);
      $function$;
      CREATE OR REPLACE FUNCTION public.get_ids_array(jsonb, text)
       RETURNS text[]
       LANGUAGE sql
       IMMUTABLE
      AS $function$
      select array_agg(x) from
         (select jsonb_array_elements($1->$2)->>'id') as f(x);
      $function$;
      CREATE INDEX flat_member_ids_idx ON orm_resources USING GIN (public.get_ids(metadata, 'member_ids'));
      CREATE INDEX flat_proxied_file_id_idx ON orm_resources USING GIN (public.get_ids_array(metadata, 'proxied_file_id'));
      CREATE INDEX flat_member_ids_array_idx ON orm_resources USING GIN (public.get_ids_array(metadata, 'member_ids'));
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX flat_member_ids_idx;
      DROP INDEX flat_proxied_file_id_idx;
      DROP INDEX flat_member_ids_array_idx;
      DROP FUNCTION public.get_ids(jsonb, field text);
      DROP FUNCTION public.get_ids_array(jsonb, field text);
    SQL
  end
end
