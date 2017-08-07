# frozen_string_literal: true
class ControlledVocabulary
  class_attribute :handlers
  self.handlers = {}
  def self.register(key, klass)
    handlers[key] = klass
  end

  def self.for(key)
    (handlers[key] || self).new
  end

  def all
    []
  end

  class Term < Valkyrie::Resource
    attribute :label, Valkyrie::Types::String
    attribute :value, Valkyrie::Types::Any
    attribute :notable, Valkyrie::Types::Bool
    attribute :definition, Valkyrie::Types::String
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

  class PDFType
    ControlledVocabulary.register(:pdf_type, self)

    def all
      [
        Term.new(label: 'Color PDF', value: 'color'),
        Term.new(label: 'Grayscale PDF', value: 'gray'),
        Term.new(label: 'Bitonal PDF', value: 'bitonal'),
        Term.new(label: 'No PDF', value: 'none')
      ]
    end
  end
end
