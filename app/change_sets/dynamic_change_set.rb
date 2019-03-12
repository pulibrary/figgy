# frozen_string_literal: true
class DynamicChangeSet
  def self.new(record, *args)
    if record.try(:change_set).present?
      class_from_param(record.change_set).new(record, *args)
    else
      class_from_param(record.internal_resource).new(record, *args)
    end
  end

  def self.class_from_param(param)
    "#{param.camelize}ChangeSet".constantize
  end
end
