# frozen_string_literal: true
require "ruby-progressbar"

namespace :figgy do
  def reindexer_solr_adapter
    if ENV["CLEAN_REINDEX_SOLR_URL"]
      :clean_reindex_solr
    else
      :reindex_solr
    end
  end

  desc "Wipes SOLR and reindexes everything."
  task wipe_and_reindex: :environment do
    batch_size = ENV["BATCH_SIZE"] || 500
    Reindexer.reindex_all(wipe: true, solr_adapter: reindexer_solr_adapter, batch_size: batch_size.to_i)
  end
  desc "Reindexes everything without wiping Solr."
  task reindex: :environment do
    batch_size = ENV["BATCH_SIZE"] || 500
    Reindexer.reindex_all(wipe: false, solr_adapter: reindexer_solr_adapter, batch_size: batch_size.to_i)
  end
  desc "Reindexes everything but FileSets without wiping Solr."
  task reindex_works: :environment do
    batch_size = ENV["BATCH_SIZE"] || 500
    Reindexer.reindex_works(wipe: false, solr_adapter: reindexer_solr_adapter, batch_size: batch_size.to_i)
  end

  namespace :geoblacklight do
    desc "Reindex Geospatial Resources (for synchronized GeoBlacklight installations)"
    task reindex: :environment do
      GeoResourceReindexer.reindex_geoblacklight
    end
  end

  namespace :orangelight do
    desc "Issue rabbitmq messages that each complete orangelight resource is updated"
    task reindex: :environment do
      OrangelightReindexer.reindex_orangelight
    end
  end
end
