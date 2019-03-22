# frozen_string_literal: true
desc "Wipes SOLR and reindexes everything."
task wipe_and_reindex: :environment do
  Reindexer.reindex_all(wipe: true)
end
desc "Reindexes everything without wiping Solr."
task reindex: :environment do
  Reindexer.reindex_all(wipe: false)
end

namespace :geoblacklight do
  desc "Reindex Geospatial Resources (for synchronized GeoBlacklight installations)"
  task reindex: :environment do
    GeoResourceReindexer.reindex_geoblacklight
  end
end
