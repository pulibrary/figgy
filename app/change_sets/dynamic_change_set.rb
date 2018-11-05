# frozen_string_literal: true
class DynamicChangeSet
  def self.new(record, *args)
    if record.try(:change_set) == "simple"
      SimpleResourceChangeSet.new(record, *args)
    elsif record.try(:change_set) == "media_reserve"
      MediaReserveChangeSet.new(record, *args)
    else
      "#{record.internal_resource}ChangeSet".constantize.new(record, *args)
    end
  end
end
