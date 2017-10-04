# frozen_string_literal: true
module QueryAdapter
  module PersistenceAdapter
    class Base
      def initialize(change_set_persister:)
        @change_set_persister = change_set_persister
      end

      def create(**args)
        save(**args)
      end
    end
  end
end
