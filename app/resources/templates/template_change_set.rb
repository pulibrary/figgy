# frozen_string_literal: true
class TemplateChangeSet < ChangeSet
  self.fields = [:title]
  property :title, required: true, multiple: false
  property :model_class, multiple: false, required: true
  property :nested_properties, type: Types::Strict::Array.of(Types::Strict::Hash), default: [{}]
  property :child_change_set_attributes, virtual: true
  property :parent_id, multiple: false, type: Valkyrie::Types::ID.optional
  validates :title, presence: true
  validates_with ParentValidator

  def child_change_set_attributes=(attributes)
    self.nested_properties = [attributes.to_unsafe_h.symbolize_keys.merge(internal_resource: model_class)]
    @child_change_set = nil
    @child_record = nil
    true
  end

  def child_change_set
    @child_change_set ||= TemplateChangeSetDecorator.new(ChangeSet.for(child_record)).tap(&:prepopulate!)
  end

  def child_record
    @child_record ||= model_class.constantize.new(nested_properties.first.to_h.symbolize_keys || {})
  end

  class TemplateChangeSetDecorator < SimpleDelegator
    def required?(_property)
      false
    end

    delegate :class, to: :__getobj__
  end
end
