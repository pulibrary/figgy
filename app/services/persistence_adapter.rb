# frozen_string_literal: true
class PersistenceAdapter
  def initialize(change_set_persister:, model:, change_set: nil)
    @change_set_persister = change_set_persister
    @model = model
    @change_set = change_set
  end

  def create(*args)
    resource = @model.new(*args)
    change_set = change_set_class.new(resource)
    change_set.validate(resource.attributes)
    yield change_set if block_given?
    return false unless change_set.sync
    @change_set_persister.save(change_set: change_set)
  end

  private

    def change_set_class_name
      "#{@model}ChangeSet".constantize
    rescue
      raise NotImplementedError, "Change Set for #{@model} not implemented."
    end

    def change_set_class
      @change_set ||= change_set_class_name
    end
end
