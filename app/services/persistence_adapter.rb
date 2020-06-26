# frozen_string_literal: true
class PersistenceAdapter
  def initialize(change_set_persister:, model:, change_set: nil)
    @change_set_persister = change_set_persister
    @model = model
    @change_set = change_set
  end

  def create(*args)
    resource = @model.new(*args)
    begin
      change_set = ChangeSet.for(resource)
    rescue
      raise NotImplementedError, "Change Set for #{@model} not implemented."
    end

    yield change_set if block_given?
    change_set.sync
    return unless change_set.validate(resource.attributes)
    @change_set_persister.save(change_set: change_set)
  end
end
