# frozen_string_literal: true
class EventGenerator
  class CompositeGenerator
    attr_reader :generators

    def initialize(generators)
      @generators = generators
    end

    def record_created(record)
      delegate_to_generator(__method__, record)
    end

    def record_deleted(record)
      delegate_to_generator(__method__, record)
    end

    def record_updated(record)
      delegate_to_generator(__method__, record)
    end

    private

      # Send method with record argument to first valid generator
      def delegate_to_generator(method_name, record)
        generator = generators.find { |g| g.valid?(record) }
        generator.send(method_name, record) if generator
      end
  end
end
