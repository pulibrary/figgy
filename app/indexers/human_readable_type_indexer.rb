# frozen_string_literal: true

class HumanReadableTypeIndexer
  class_attribute :change_sets
  self.change_sets = [
    ArchivalMediaCollectionChangeSet
  ]

  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless decorated_resource.try(:human_readable_type)
    {
      human_readable_type_ssim: human_readable_type
    }
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end

  private

    def index_change_set?(change_set)
      change_set_class_name = "#{change_set.camelize}ChangeSet"
      change_set_class = change_set_class_name.constantize
      self.class.change_sets.include?(change_set_class)
    rescue NameError
      Valkyrie.logger.warn("#{change_set} is not a valid resource type.")
      false
    end

    def human_readable_type
      return Array.wrap(resource.class.to_s) + [decorated_resource.human_readable_type] if decorated_resource.try(:change_set) && index_change_set?(decorated_resource.change_set)

      decorated_resource.human_readable_type
    end
end
