# frozen_string_literal: true
require "reform/form/active_model/form_builder_methods"
class ChangeSet < Valkyrie::ChangeSet
  include Reform::Form::ActiveModel
  include Reform::Form::ActiveModel::FormBuilderMethods
  class_attribute :workflow_class
  class_attribute :feature_terms

  # Delegating the to_hash method to the resource is a workaround that allows
  # syncing of the changeset. Reform does not appear to de-cast forms during sync.
  delegate :to_hash, to: :resource
  self.feature_terms = []
  def self.apply_workflow(workflow)
    self.workflow_class = workflow
    include(ChangeSetWorkflow)
  end

  def self.core_resource(change_set: nil)
    delegate :human_readable_type, to: :model
    property :title, multiple: true, required: true, default: []
    validates_with TitleValidator
    # Rights
    property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
    property :rights_note, multiple: false, required: false
    validates_with RightsStatementValidator
    # Visibility
    include VisibilityProperty
    validates :visibility, presence: true
    property :read_groups, multiple: true, required: false
    # File Upload
    property :files, virtual: true, multiple: true, required: false
    property :pending_uploads, multiple: true, required: false
    # Collections
    property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    validates_with CollectionValidator
    property(:change_set, require: true, default: change_set) if change_set
    self.feature_terms += [:title, :rights_statement, :rights_note]
    self.feature_terms += [:change_set] if change_set
  end

  def self.enable_order_manager
    property :viewing_hint, multiple: false, required: false, default: "individuals"
    property :viewing_direction, multiple: false, required: false
    property :nav_date, multiple: false, required: false
    property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
    property :start_canvas, multiple: false, type: Valkyrie::Types::ID.optional
    validates_with ViewingDirectionValidator
    validates_with ViewingHintValidator
    validates_with MemberValidator
  end

  def self.enable_pdf_support
    property :pdf_type, multiple: false, required: false, default: "color"
    property :file_metadata, multiple: true, required: false, default: []
    self.feature_terms += [:pdf_type]
  end

  # This property is set by ChangeSetPersister::CreateFile and is used to keep
  # track of which FileSets were created by the ChangeSetPersister as part of
  # saving this change_set. We may want to look into passing some sort of scope
  # around with the change_set in ChangeSetPersister instead, at some point.
  property :created_file_sets, virtual: true, multiple: true, required: false, default: []

  def initialize(*args)
    super.tap do
      fix_multivalued_keys
    end
  end

  # This is a temporary fix to deal with the fact that we have change sets which
  # are set to be singular when the model is set to be multiple. REMOVE THIS as
  # soon as the model has single-value fields in places where it makes sense.
  #
  # @todo: REMOVE THIS.
  def fix_multivalued_keys
    self.class.definitions.select { |_field, definition| definition[:multiple] == false }.each_key do |field|
      value = Array.wrap(send(field.to_s)).first
      send("#{field}=", value)
    end
    @_changes = Disposable::Twin::Changed::Changes.new
  end

  # Defines the default populator for a nested single-valued changeset property
  def populate_nested_property(fragment:, as:, **)
    property_klass = model.class.schema[as.to_sym]
    if fragment.values.select(&:present?).blank?
      send(:"#{as}=", nil)
      return skip!
    end

    send("#{as.to_sym}=", property_klass.new(fragment))
  end

  # Override prepopulate method to correctly populate nested properties.
  def prepopulate!(_args = {})
    # Applying the twin filter to schema finds all nested properties
    schema.each(twin: true) do |property|
      property_name = property[:name]
      property_klass = model.class.schema[property_name.to_sym]
      send(:"#{property_name}=", property_klass.new) unless send(property_name)
    end

    super
  end
end
