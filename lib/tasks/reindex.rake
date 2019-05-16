# frozen_string_literal: true
require "ruby-progressbar"

def reindexer_solr_adapter
  if ENV["CLEAN_REINDEX_SOLR_URL"]
    :clean_reindex_solr
  else
    :index_solr
  end
end

desc "Wipes SOLR and reindexes everything."
task wipe_and_reindex: :environment do
  Reindexer.reindex_all(wipe: true, solr_adapter: reindexer_solr_adapter)
end
desc "Reindexes everything without wiping Solr."
task reindex: :environment do
  Reindexer.reindex_all(wipe: false, solr_adapter: reindexer_solr_adapter)
end
desc "Reindexes everything but FileSets without wiping Solr."
task reindex_works: :environment do
  Reindexer.reindex_works(wipe: false, solr_adapter: reindexer_solr_adapter)
end

namespace :geoblacklight do
  desc "Reindex Geospatial Resources (for synchronized GeoBlacklight installations)"
  task reindex: :environment do
    GeoResourceReindexer.reindex_geoblacklight
  end
end
