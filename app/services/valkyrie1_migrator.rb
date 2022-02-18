# frozen_string_literal: true

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
