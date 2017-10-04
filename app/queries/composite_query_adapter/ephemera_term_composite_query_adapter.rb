# frozen_string_literal: true
class CompositeQueryAdapter
  class EphemeraTermCompositeQueryAdapter < CompositeQueryAdapter
    class_attribute :query_adapter_class
    self.query_adapter_class = QueryAdapter::EphemeraTermQueryAdapter
    class_attribute :persistence_adapter_class
    self.persistence_adapter_class = QueryAdapter::PersistenceAdapter::EphemeraTermPersistenceAdapter
  end
end
