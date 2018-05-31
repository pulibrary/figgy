# frozen_string_literal: true
# Service Class for migrating from Valkyrie 0.x releases to 1.0
# Please note that this approach should not be undertaken for future migrations
class Valkyrie1Migrator
  def self.call
    [EphemeraTerm, EphemeraVocabulary].each do |model|
      query_service.find_all_of_model(model: model).each do |resource|
        adapter.persister.save(resource: resource)
      end
    end
  end

  def self.adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def self.query_service
    adapter.query_service
  end
end
