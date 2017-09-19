# frozen_string_literal: true
class ControlledVocabulary
  class_attribute :handlers
  self.handlers = {}
  def self.register(key, klass)
    handlers[key] = klass
  end

  def self.for(key)
    (handlers[key] || self).new(key: key)
  end

  attr_reader :key
  def initialize(key: nil)
    @key = key
  end

  def all
    []
  end

  def find(value)
    all.find { |x| x.value == value }
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

  class BookWorkflow < ControlledVocabulary
    include Draper::ViewHelpers
    ControlledVocabulary.register(:state_book_workflow, self)
    ControlledVocabulary.register(:state_folder_workflow, self)
    ControlledVocabulary.register(:state_box_workflow, self)

    def all(scope = nil)
      @all ||=
        workflow_class.new(scope.state).valid_transitions.unshift(scope.state).map do |state|
          Term.new(label: view_label(state), value: state)
        end
    end

    def workflow_class
      @workflow_class ||= key.to_s.gsub("state_", "").camelize.constantize
    end

    def view_label(state)
      badge(state) + label(state)
    end

    def badge(state)
      h.content_tag(:span, I18n.t("state.#{state}.label"), class: "label #{dom_label_class(state)}")
    end

    def label(state)
      " " + I18n.t("state.#{state}.desc")
    end

    def dom_label_class(state)
      state_classes[state.to_sym] if state
    end

    def state_classes
      @state_classes ||= {
        new: 'label-default',
        pending: 'label-default',
        needs_qa: 'label-info',
        metadata_review: 'label-info',
        final_review: 'label-primary',
        complete: 'label-success',
        flagged: 'label-warning',
        takedown: 'label-danger',
        ready_to_ship: 'label-info',
        shipped: 'label-info',
        received: 'label-default',
        all_in_production: 'label-success'
      }
    end
  end

  class RightsStatement < ControlledVocabulary
    ControlledVocabulary.register(:rights_statement, self)
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "rights_statement.yml")), [Symbol])
    end

    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end

  class PDFType < ControlledVocabulary
    ControlledVocabulary.register(:pdf_type, self)

    def all(_scope = nil)
      [
        Term.new(label: 'Color PDF', value: 'color'),
        Term.new(label: 'Grayscale PDF', value: 'gray'),
        Term.new(label: 'Bitonal PDF', value: 'bitonal'),
        Term.new(label: 'No PDF', value: 'none')
      ]
    end
  end

  class HoldingLocation < ControlledVocabulary
    ControlledVocabulary.register(:holding_location, self)

    def all(_scope = nil)
      json.map do |record|
        Term.new(label: record[:label], value: record[:url].gsub('.json', ''))
      end
    end

    def url
      Figgy.config['locations_url']
    end

    def json
      @json ||= MultiJson.load(Faraday.get(url).body, symbolize_keys: true)
    end
  end
end
