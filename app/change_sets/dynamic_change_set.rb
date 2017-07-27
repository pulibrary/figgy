# frozen_string_literal: true
class DynamicChangeSet
  def self.new(record, *args)
    "#{record.internal_resource}ChangeSet".constantize.new(record, *args)
  end
end
