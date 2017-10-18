# frozen_string_literal: true
desc "Imports an ID from Plum"
task reindex: :environment do
  Reindexer.reindex_all
end
