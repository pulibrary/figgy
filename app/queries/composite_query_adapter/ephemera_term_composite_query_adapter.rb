# frozen_string_literal: true
module CompositeQueryAdapter
  class EphemeraTermCompositeQueryAdapter < Base
    class_attribute :query_adapter_class
    self.query_adapter_class = QueryAdapter::EphemeraTermQueryAdapter
    class_attribute :persistence_adapter_class
    self.persistence_adapter_class = QueryAdapter::PersistenceAdapter::EphemeraTermPersistenceAdapter
  end
end
