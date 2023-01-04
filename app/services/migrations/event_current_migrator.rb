# frozen_string_literal: true

module Migrations
  class EventCurrentMigrator
    def self.call
      new.run
    end

    def run
      update_query = pg_adapter.connection[update_current_query]
      update_query.update
    end

    def update_current_query
      <<-SQL
        WITH ranked_events AS (
          SELECT res.*, ROW_NUMBER() OVER(PARTITION BY res.metadata->>'child_id' ORDER BY res.updated_at DESC) AS rank
          FROM orm_resources res
          WHERE res.internal_resource = 'Event'
        )
        UPDATE orm_resources event
        SET metadata = event.metadata || '{"current": true}'
        FROM (
          SELECT *
          FROM ranked_events
          WHERE ranked_events.rank = 1
        ) as top_events
        WHERE top_events.id = event.id
      SQL
    end

    def pg_adapter
      @pg_adapter ||= Valkyrie::MetadataAdapter.find(:postgres).query_service.adapter
    end
  end
end
