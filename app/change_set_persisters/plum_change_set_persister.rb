# frozen_string_literal: true
class PlumChangeSetPersister
  attr_reader :metadata_adapter, :storage_adapter
  delegate :persister, :query_service, to: :metadata_adapter
  def initialize(metadata_adapter:, storage_adapter:)
    @metadata_adapter = metadata_adapter
    @storage_adapter = storage_adapter
  end

  def save(change_set:)
    before_save(change_set: change_set)
    persister.save(resource: change_set.resource).tap do |output|
      after_save(change_set: change_set, updated_resource: output)
    end
  end

  def delete(change_set:)
    before_delete(change_set: change_set)
    persister.delete(resource: change_set.resource)
  end

  def save_all(change_sets:)
    change_sets.map do |change_set|
      save(change_set: change_set)
    end
  end

  def with(metadata_adapter:)
    yield self.class.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter)
  end

  private

    def before_save(change_set:); end

    def after_save(change_set:, updated_resource:); end

    def before_delete(change_set:); end
end
