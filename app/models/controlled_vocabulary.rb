# frozen_string_literal: true

# Base Class for controlled vocabularies for local authorities
# Terms within these vocabularies are stored within YAML files
# *Please* note that these are distinct from EphemeraVocabulary and Vocab Classes
class ControlledVocabulary
  class_attribute :handlers
  self.handlers = {}

  # Mutates the Class attribute mapping a key symbol to a ControlledVocabulary subclass
  # @param key [Symbol] the symbolized name of the registered vocabulary
  # @param klass [Class] the ControlledVocabulary subclass
  def self.register(key, klass)
    handlers[key] = klass
  end

  # Accesses the Class mapped to a key symbol for a ControlledVocabulary subclass
  # @param key [Symbol] the symbolized name for the registered vocabulary
  # @return [Class] the ControlledVocabulary subclass
  def self.for(key)
    (handlers[key] || self).new(key: key)
  end

  # Initializer for the ControlledVocabulary
  attr_reader :key
  # @param key [Symbol] the symbolized name for the vocabulary
  def initialize(key: nil)
    @key = key
  end

  # Method returning all terms within the vocabulary
  # This should be overridden
  def all
    []
  end

  # Accesses a Term Object matching a specific value
  # @param value [String] the value for the Term being searched for
  # @return [Term] the Term Object within the vocabulary
  def find(value)
    all.find { |x| x.value == value }
  end

  # Method which determines whether or not a Term Object containing a value exists in this vocabulary
  # @param value [String] the value for Term
  # @return [Boolean] whether or not the Term is included in this vocabulary
  def include?(value)
    !find(value).nil?
  end

  # Base Class for terms within a ControlledVocabulary
  # Please note that this Class does *not* contain a property for term ownership
  class Term < Valkyrie::Resource
    attribute :label, Valkyrie::Types::String
    attribute :value, Valkyrie::Types::Any
    attribute :notable, Valkyrie::Types::Bool
    attribute :definition, Valkyrie::Types::String

    # Whether or not this Term has been marked as notable
    # @return [Boolean] whether or not this Term is notable
    def notable?
      notable == true
    end
  end

  # Vocabulary for modeling workflow states for bibliographic resources (Books)
  # Please note that this is used in capturing the workflow state for books, ephemera folders, and ephemera boxes
  class BookWorkflow < ControlledVocabulary
    include Draper::ViewHelpers
    ControlledVocabulary.register(:state_book_workflow, self)
    ControlledVocabulary.register(:state_folder_workflow, self)
    ControlledVocabulary.register(:state_box_workflow, self)

    # Access all of the terms within this vocabulary
    # @param scope an object restricting the terms retrieved
    # @return [Array<Term>] Terms containing the workflow state and HTML for the state Twitter Bootstrap "badge"
    def all(scope = nil)
      @all ||=
        workflow_class.new(scope.state).valid_transitions.unshift(scope.state).map do |state|
          Term.new(label: view_label(state), value: state)
        end
    end

    # Accesses the workflow class
    # Uses the @key attribute to generate the Class name
    # e. g. :state_foo_workflow becomes FooWorkflow
    # @return [Class] the Class for the workflow vocabulary
    def workflow_class
      @workflow_class ||= key.to_s.gsub("state_", "").camelize.constantize
    end

    # Generates the HTML for rendering the workflow state label
    # @return [String] the markup for the state label
    def view_label(state)
      badge(state) + label(state)
    end

    # Generates the HTML for the Twitter Bootstrap badge given a state
    # @param state [String] the state for which the badge should be generated
    # @return [String] the HTML for the Bootstrap badge
    def badge(state)
      h.content_tag(:span, I18n.t("state.#{state}.label"), class: "label #{dom_label_class(state)}")
    end

    # Retrieves the label for a state using the app. locale
    # @param state [String] the state being labeled
    # @return [String] the internationalized label for the state
    def label(state)
      " " + I18n.t("state.#{state}.desc")
    end

    # Retrieves the HTML class for the Bootstrap badge markup using the state
    # @param state [String] the state for which the HTML class is required
    # @return [String] the HTML class for the element
    def dom_label_class(state)
      state_classes[state.to_sym] if state
    end

    # Access the Hash mapping state values as key symbols to HTML classes
    # @return [Hash] the state to HTML class mapping
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

  # Controlled vocabulary for rights statements
  # @see http://rightsstatements.org/en/
  class RightsStatement < ControlledVocabulary
    ControlledVocabulary.register(:rights_statement, self)
    # Accessor for the class attribute storing the rights statements within an authorities YAML file
    # @return [Hash] the parsed rights statement authorities files
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "rights_statement.yml")), [Symbol])
    end

    # Accesses all Terms specified within the YAML config. files
    # @return [Array<Term>] the Term Objects modeling each rights statement
    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end

  # Controlled vocabulary for raster geospatial media types
  class GeoImageFormat < ControlledVocabulary
    ControlledVocabulary.register(:geo_image_format, self)
    # Accessor for the class attribute storing the media types within an authorities YAML file
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "geo_image_formats.yml")), [Symbol])
    end

    # Accesses all Terms specified within the YAML config. files
    # @return [Array<Term>] the Term Objects modeling each geospatial raster media type
    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end

  # Controlled vocabulary for geospatial metadata media types
  class GeoMetadataFormat < ControlledVocabulary
    ControlledVocabulary.register(:geo_metadata_format, self)
    # Accessor for the class attribute storing the geospatial metadata media types within an authorities YAML file
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "geo_metadata_formats.yml")), [Symbol])
    end

    # Accesses all Terms specified within the YAML config. files
    # @return [Array<Term>] the Term Objects modeling each geospatial metadata media type
    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end

  # Controlled vocabulary for vector geospatial media types
  class GeoVectorFormat < ControlledVocabulary
    ControlledVocabulary.register(:geo_vector_format, self)
    # Accessor for the class attribute storing the media types within an authorities YAML file
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "geo_vector_formats.yml")), [Symbol])
    end

    # Accesses all Terms specified within the YAML config. files
    # @return [Array<Term>] the Term Objects modeling each geospatial vector media type
    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end

  # Controlled vocabulary for raster geospatial media types
  class GeoRasterFormat < ControlledVocabulary
    ControlledVocabulary.register(:geo_raster_format, self)
    # Accessor for the class attribute storing the media types within an authorities YAML file
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "geo_raster_formats.yml")), [Symbol])
    end

    # Accesses all Terms specified within the YAML config. files
    # @return [Array<Term>] the Term Objects modeling each geospatial raster media type
    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end

  # Controlled vocabulary for ISO language codes
  # Unlike with other authorities, no YAML file is used for these values
  class Language < ControlledVocabulary
    ControlledVocabulary.register(:language, self)

    # Accesses all Terms mapped to ISO language codes
    # @return [Array<Term>] the Term Objects modeling each language code
    def all(_scope = nil)
      ISO_639::ISO_639_1.map(&:first).uniq.map do |value|
        find(value)
      end
    end

    # Retrieve a Term with a specific ISO language code as a value
    # @param value [String] the ISO language code
    # @return [Term] the Term Object modeling the language code
    def find(value)
      Term.new(label: label(value), value: value)
    end

    # Retrieve the human-readable label for an ISO language code
    # @param value [String] the ISO language code
    # @return [String] the human-readable label (if it could be found)
    def label(value)
      ISO_639.find_by_code(value).try(:english_name) || value
    end
  end

  # Controlled vocabularies for PDF types
  # Unlike with other authorities, no YAML file is used for these values
  class PDFType < ControlledVocabulary
    ControlledVocabulary.register(:pdf_type, self)

    # Retrieve all Terms structuring the types of PDF's
    # @return [Array<Term>] the Term Objects modeling each PDF type
    def all(_scope = nil)
      [
        Term.new(label: 'Color PDF', value: 'color'),
        Term.new(label: 'Grayscale PDF', value: 'gray'),
        Term.new(label: 'Bitonal PDF', value: 'bitonal'),
        Term.new(label: 'No PDF', value: 'none')
      ]
    end
  end

  # Controlled vocabularies for holding locations for a given cataloged item
  # Values for this vocabulary are unique in that they are parsed from PULFA
  class HoldingLocation < ControlledVocabulary
    ControlledVocabulary.register(:holding_location, self)

    # Retrieve all Terms within the vocabulary
    # @return [Array<Term>] the Term Objects capturing the most recently holding location for an item
    def all(_scope = nil)
      json.map do |record|
        Term.new(label: record[:label], value: record[:url].gsub('.json', ''))
      end
    end

    # Access the URL for the PULFA locations endpoint from the app. config.
    # @return [String] the endpoint URL
    def url
      Figgy.config['locations_url']
    end

    # Query and retrieve for the holding location from PULFA over the HTTP
    # @return [Hash] the HTTP response body retrieved and parsed from the JSON
    def json
      @json ||= MultiJson.load(Faraday.get(url).body, symbolize_keys: true)
    end
  end

  # Controlled vocabulary for the ephemera fields names
  class EphemeraField < ControlledVocabulary
    ControlledVocabulary.register(:ephemera_field, self)
    # Parse the YAML file containing the authorities for each Ephemera Field name
    # @return [Hash] values for the configuration
    def self.authority_config
      @authority_config ||= YAML.safe_load(File.read(Rails.root.join("config", "authorities", "ephemera_field_name.yml")), [Symbol])
    end

    # Retrieve all Terms within the vocabulary
    # @return [Array<Term>] the Term Objects capturing the name for ephemera fields
    def all(_scope = nil)
      @all ||=
        self.class.authority_config[:terms].map do |term|
          Term.new(term)
        end
    end
  end
end
