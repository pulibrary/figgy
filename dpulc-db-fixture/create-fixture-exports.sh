#!/bin/bash

# Women Life Freedom Movement: Iran 2022
PROJECT_ID=2961c153-54ab-4c6a-b5cd-aa992f4c349b

# Export the project
ssh deploy@figgy-web-prod1.princeton.edu "cd /opt/figgy/current && PGPASSWORD=\$FIGGY_DB_RO_PASSWORD psql -d \$FIGGY_DB -U \$FIGGY_DB_RO_USERNAME -h \$FIGGY_DB_HOST -c \"\\copy (select * from orm_resources WHERE id = '$PROJECT_ID') TO '/tmp/project-export.binary' BINARY\""

# Export the project members recursively
# This will get all the Boxes, Folders, and FileSets
MEMBERS_QUERY=$(cat <<-END
  WITH RECURSIVE deep_members AS (
    select member.*
    FROM orm_resources a,
    jsonb_array_elements(a.metadata->'member_ids') AS b(member)
    JOIN orm_resources member ON (b.member->>'id')::UUID = member.id
    WHERE a.id = '${PROJECT_ID}'
    UNION
    SELECT mem.*
    FROM deep_members f,
    jsonb_array_elements(f.metadata->'member_ids') AS g(member)
    JOIN orm_resources mem ON (g.member->>'id')::UUID = mem.id
    WHERE f.metadata @> '{\"member_ids\": [{}]}'
  )
  select * from deep_members
END
)

ssh deploy@figgy-web-prod1.princeton.edu "cd /opt/figgy/current && PGPASSWORD=\$FIGGY_DB_RO_PASSWORD psql -d \$FIGGY_DB -U \$FIGGY_DB_RO_USERNAME -h \$FIGGY_DB_HOST -c \"\\copy ($MEMBERS_QUERY) TO '/tmp/project-members-export.binary' BINARY\""

# Just export all the ephemera vocabularies and terms, so we have them.
VOCABULARY_QUERY=$(cat <<-END
  select * from orm_resources WHERE internal_resource = 'EphemeraVocabulary' OR internal_resource = 'EphemeraTerm'
END
)

ssh deploy@figgy-web-prod1.princeton.edu "cd /opt/figgy/current && PGPASSWORD=\$FIGGY_DB_RO_PASSWORD psql -d \$FIGGY_DB -U \$FIGGY_DB_RO_USERNAME -h \$FIGGY_DB_HOST -c \"\\copy ($VOCABULARY_QUERY) TO '/tmp/project-vocabulary-export.binary' BINARY\""

# Get the DB schema
#
#
ssh deploy@figgy-web-prod1.princeton.edu "cd /opt/figgy/current && PGPASSWORD=\$FIGGY_DB_RO_PASSWORD pg_dump -U \$FIGGY_DB_RO_USERNAME -h \$FIGGY_DB_HOST -f /tmp/db-schema.sql --schema-only \$FIGGY_DB"
