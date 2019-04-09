# frozen_string_literal: true
require "reform/form/active_model/form_builder_methods"
class ChangeSet < Valkyrie::ChangeSet
  def self.reflect_on_association(*_args); end
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

  def self.enable_preservation_support
    property :preservation_policy, multiple: false, required: false, default: nil
    self.feature_terms += [:preservation_policy]
    define_method :preserve? do
      return false unless persisted? && resource.respond_to?(:preservation_policy)
      parent = Wayfinder.for(resource).try(:parent)
      if parent.present? && parent.id != resource.id
        DynamicChangeSet.new(parent).try(:preserve?)
      else
        resource.preservation_policy.present? && state == "complete"
      end
    end
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

  def populate_nested_collection(fragment:, as:, collection:, index:, **)
    property_klass = model.class.schema[as.to_sym]
    item = collection.find { |x| x.id.to_s == fragment["id"] }
    if item
      if delete_fragment?(fragment)
        collection.delete_at(index)
        return skip!
      else
        item
      end
    elsif delete_fragment?(fragment)
      skip!
    else
      collection.append(property_klass[[{ id: SecureRandom.uuid }]].first)
    end
  end

  def delete_fragment?(fragment)
    fragment["_destroy"] == "1" || fragment.values.select(&:present?).blank?
  end

  # Override prepopulate method to correctly populate nested properties.
  def prepopulate!(_args = {})
    # Applying the twin filter to schema finds all nested properties
    schema.each(twin: true) do |property|
      property_name = property[:name]
      property_klass = model.class.schema[property_name.to_sym]
      next if send(property_name).present?
      if property_klass.respond_to?(:primitive) && property_klass.primitive == Array
        send(:"#{property_name}=", property_klass[[{}]])
      end
    end

    super
  end
end
