# frozen_string_literal: true
class PlumChangeSetPersister
  class_attribute :registered_handlers
  self.registered_handlers = {}

  def self.register_handler(action, handler)
    raise "Invalid action #{action} given. Must be one of #{valid_actions.to_sentence}." unless valid_actions.include?(action)
    registered_handlers[action] ||= []
    registered_handlers[action] << handler
  end

  def self.valid_actions
    [
      :before_save,
      :after_save,
      :before_delete,
      :after_commit
    ]
  end
  # Eager load these files to ensure they register with the ChangeSetPersister.
  Dir[__dir__ + '/plum_change_set_persister/*.rb'].each do |file|
    require_dependency file
  end

  attr_reader :metadata_adapter, :storage_adapter, :created_file_sets, :file_appender
  attr_accessor :created_file_sets
  delegate :persister, :query_service, to: :metadata_adapter
  def initialize(metadata_adapter:, storage_adapter:, transaction: false, file_appender: FileAppender, characterize: true)
    @metadata_adapter = metadata_adapter
    @storage_adapter = storage_adapter
    @transaction = transaction
    @file_appender = file_appender
    @characterize = characterize
  end

  def save(change_set:)
    before_save(change_set: change_set)
    persister.save(resource: change_set.resource).tap do |output|
      after_save(change_set: change_set, updated_resource: output)
      after_commit unless transaction?
    end
  end

  def delete(change_set:)
    before_delete(change_set: change_set)
    persister.delete(resource: change_set.resource).tap do
      after_commit unless transaction?
    end
  end

  def save_all(change_sets:)
    change_sets.map do |change_set|
      save(change_set: change_set)
    end
  end

  def buffer_into_index
    metadata_adapter.persister.buffer_into_index do |buffered_adapter|
      with(metadata_adapter: buffered_adapter) do |buffered_changeset_persister|
        yield(buffered_changeset_persister)
        @created_file_sets = buffered_changeset_persister.created_file_sets
      end
    end
    after_commit
  end

  def transaction?
    @transaction
  end

  def characterize?
    @characterize
  end

  def with(metadata_adapter:)
    yield self.class.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter, transaction: true, file_appender: file_appender, characterize: @characterize)
  end

  private

    def before_save(change_set:)
      registered_handlers.fetch(:before_save, []).each do |handler|
        handler.new(change_set_persister: self, change_set: change_set).run
      end
    end

    def after_save(change_set:, updated_resource:)
      registered_handlers.fetch(:after_save, []).each do |handler|
        handler.new(change_set_persister: self, change_set: change_set, post_save_resource: updated_resource).run
      end
    end

    def before_delete(change_set:)
      registered_handlers.fetch(:before_delete, []).each do |handler|
        handler.new(change_set_persister: self, change_set: change_set).run
      end
    end

    def after_commit
      registered_handlers.fetch(:after_commit, []).each do |handler|
        handler.new(change_set_persister: self, change_set: nil).run
      end
    end
end
