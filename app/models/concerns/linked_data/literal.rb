# frozen_string_literal: true

# This is a null object
module LinkedData
  class Literal
    attr_reader :value

    def initialize(value:)
      @value = value
    end

    delegate :to_s, to: :value
    alias_method :as_json, :to_s
    alias_method :without_context, :as_json
  end
end
