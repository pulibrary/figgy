# frozen_string_literal: true
module CompositeQueryAdapter
  class EphemeraVocabularyCompositeQueryAdapter < Base
    class_attribute :query_adapter_class
    self.query_adapter_class = QueryAdapter::EphemeraVocabularyQueryAdapter
    class_attribute :persistence_adapter_class
    self.persistence_adapter_class = QueryAdapter::PersistenceAdapter::EphemeraVocabularyPersistenceAdapter
  end
end
