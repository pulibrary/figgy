# frozen_string_literal: true
class QueryAdapter
  class PersistenceAdapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def create(**args)
      save(**args)
    end
  end
end
