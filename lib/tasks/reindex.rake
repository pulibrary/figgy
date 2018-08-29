# frozen_string_literal: true
desc "Wipes SOLR and reindexes everything."
task wipe_and_reindex: :environment do
  Reindexer.reindex_all(wipe: true)
end
desc "Reindexes everything without wiping Solr."
task reindex: :environment do
  Reindexer.reindex_all(wipe: false)
end
