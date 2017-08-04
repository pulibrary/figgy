# frozen_string_literal: true
class ControlledVocabulary
  class_attribute :handlers
  self.handlers = {}
  def self.register(key, klass)
    handlers[key] = klass
  end

  def self.for(key)
    handlers[key].new || new
  end

  def all
    []
  end

  class Term < Dry::Struct
    attribute :label, Valkyrie::Types::String
    attribute :value, Valkyrie::Types::Any
    attribute :notable, Valkyrie::Types::Bool
    def notable?
      notable == true
    end
  end

  class RightsStatement
    ControlledVocabulary.register(:rights_statement, self)
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "rights_statement.yml")), [Symbol])
    end

    def all
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end

    def find(value)
      all.find { |x| x.value == value }
    end
  end
end
