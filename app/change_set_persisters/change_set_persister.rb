# frozen_string_literal: true
class ChangeSetPersister
  def self.new(metadata_adapter:, storage_adapter:, transaction: false, characterize: true, queue: :default)
    Basic.new(metadata_adapter: metadata_adapter,
              storage_adapter: storage_adapter,
              transaction: transaction,
              characterize: characterize,
              queue: queue,
              handlers: registered_handlers)
  end

  def self.default
    @default ||= new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
  end

  # rubocop:disable Metrics/MethodLength
  def self.registered_handlers
    {
      before_save: [
        AppendToCollection,
        RemoveFromCollection,
        RemoveFileMetadata,
        SyncResource,
        MintIdentifier,
        ApplyRemoteMetadata,
        ClearRemoteMetadata,
        ExtractArchivalCollectionCode,
        ApplyVisibilityByDate,
        RestoreFromDeletionMarkers,
        CreateFile::Factory.new(file_appender: FileAppender),
        PropagateVisibilityAndState,
        PropagateOCRLanguage,
        CleanupPdfs,
        CreateProxyFileSets,
        ApplyAuthToken,
        CacheParentId,
        UpdateCloudFilePermissions
      ],
      after_save: [
        UpdateAuthToken,
        GenerateMosaic
      ],
      around_save: [
        AppendToParent
      ],
      after_save_commit: [
        PublishMessage::Factory.new(operation: :update),
        ReindexChildrenOnState::Factory.new(model: EphemeraBox, state: "all_in_production"),
        IngestBag,
        PreserveResource,
        ReorganizeCollection,
        UpdateAspaceDao,
        CleanupDeletedFiles,
        Characterize
      ],
      after_update_commit: [
        ReindexCollectionMembers,
        UpdateOCR
      ],
      before_delete: [
        CreateDeletionMarker,
        CleanupPDFDerivatives,
        CleanupMosaic,
        CleanupFiles,
        CleanupStructure,
        DeleteReferenced::Factory.new(property: :member_of_vocabulary_id),
        CleanupMembership::Factory.new(property: :member_ids),
        CleanupMembership::Factory.new(property: :member_of_collection_ids),
        PublishMessage::Factory.new(operation: :derivatives_delete),
        DeleteReferenced::Factory.new(property: :preserved_object_id),
        CleanupTerms,
        DeleteReferenced::Factory.new(property: :resource_id, parent_model: PreservationObject)
      ],
      after_delete_commit: [
        DeleteAuthToken,
        DeleteMembers::Factory.new(property: :member_ids),
        PublishMessage::Factory.new(operation: :delete),
        CleanupPreservation
      ],
      after_commit: [
        PublishMessage::Factory.new(operation: :create)
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength

  class Basic
    attr_reader :metadata_adapter, :storage_adapter, :handlers
    attr_accessor :queue
    attr_writer :after_rollback
    delegate :persister, :query_service, to: :metadata_adapter
    def initialize(metadata_adapter:, storage_adapter:, transaction: false, characterize: true, queue: :default, handlers: {})
      @metadata_adapter = metadata_adapter
      @storage_adapter = storage_adapter
      @transaction = transaction
      @characterize = characterize
      @handlers = handlers
      @queue = queue
    end

    def registered_handlers
      handlers
    end

    def prevent_propagation!
      @handlers[:before_save] -= [PropagateVisibilityAndState, PropagateOCRLanguage]
    end

    def save(change_set:, external_resource: false)
      before_save(change_set: change_set)
      persister.save(resource: change_set.resource, external_resource: external_resource).tap do |output|
        after_save(change_set: change_set, updated_resource: output)
        # Invoke the "after_update_commit" handlers only if this resource has already been persisted
        after_update_commit(change_set: change_set) if change_set.persisted?

        after_save_commit(change_set: change_set, updated_resource: output)
        after_commit(change_set: change_set)
      end
    end

    def delete(change_set:)
      before_delete(change_set: change_set)
      persister.delete(resource: change_set.resource).tap do
        after_delete_commit(change_set: change_set)
      end
    end

    def save_all(change_sets:)
      change_sets.map do |change_set|
        save(change_set: change_set)
      end
    end

    def buffer_into_index
      if transaction?
        yield self
        return
      end

      delayed_queue = nil
      @after_rollback = DelayedQueue.new
      metadata_adapter.persister.buffer_into_index do |buffered_adapter|
        with(metadata_adapter: buffered_adapter) do |buffered_changeset_persister|
          yield(buffered_changeset_persister)
          delayed_queue = buffered_changeset_persister.delayed_queue
        end
      end
      @after_rollback = nil
      delayed_queue.run
    rescue StandardError => error
      after_rollback.run
      @after_rollback = nil
      raise error
    end

    def transaction?
      @transaction
    end

    def characterize?
      @characterize
    end

    def delayed_queue
      @delayed_queue ||=
        if transaction?
          DelayedQueue.new
        else
          InstantQueue.new
        end
    end

    def after_rollback
      @after_rollback ||=
        if transaction?
          DelayedQueue.new
        else
          InstantQueue.new
        end
    end

    class DelayedQueue
      def initialize
        @blocks = []
      end

      def add(&block)
        @blocks << block
      end

      def run
        @blocks.each(&:call)
        @blocks = []
      end
    end

    class InstantQueue
      def add
        yield
      end

      def run; end
    end

    # Provides an easy way to safely get a new instance of the change set
    # persister with different initialization parameters. If passed a block it
    # will yield the new adapter.
    def with(metadata_adapter: self.metadata_adapter, storage_adapter: self.storage_adapter)
      new_adapter = self.class.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter, transaction: true, characterize: @characterize, queue: queue, handlers: handlers)
      new_adapter.after_rollback = after_rollback
      return new_adapter unless block_given?
      yield new_adapter
    end

    def messenger
      @messenger ||= EventGenerator.new
    end

    private

      def before_save(change_set:)
        registered_handlers.fetch(:around_save, []).each do |handler|
          handler.new(change_set_persister: self, change_set: change_set, post_save_resource: nil).run_before_save
        end
        registered_handlers.fetch(:before_save, []).each do |handler|
          handler.new(change_set_persister: self, change_set: change_set).run
        end
      end

      def after_save(change_set:, updated_resource:)
        registered_handlers.fetch(:after_save, []).each do |handler|
          handler.new(change_set_persister: self, change_set: change_set, post_save_resource: updated_resource).run
        end
        registered_handlers.fetch(:around_save, []).each do |handler|
          handler.new(change_set_persister: self, change_set: change_set, post_save_resource: updated_resource).run_after_save
        end
      end

      def after_save_commit(change_set:, updated_resource:)
        registered_handlers.fetch(:after_save_commit, []).each do |handler|
          instance = handler.new(change_set_persister: self, change_set: change_set, post_save_resource: updated_resource)
          delayed_queue.add do
            instance.run
          end
        end
      end

      def after_update_commit(change_set:)
        registered_handlers.fetch(:after_update_commit, []).each do |handler|
          instance = handler.new(change_set_persister: self, change_set: change_set)
          delayed_queue.add do
            instance.run
          end
        end
      end

      def before_delete(change_set:)
        registered_handlers.fetch(:before_delete, []).each do |handler|
          handler.new(change_set_persister: self, change_set: change_set).run
        end
      end

      def after_delete_commit(change_set:)
        registered_handlers.fetch(:after_delete_commit, []).each do |handler|
          instance = handler.new(change_set_persister: self, change_set: change_set)
          delayed_queue.add do
            instance.run
          end
        end
      end

      def after_commit(change_set:)
        registered_handlers.fetch(:after_commit, []).each do |handler|
          instance = handler.new(change_set_persister: self, change_set: change_set)
          delayed_queue.add do
            instance.run
          end
        end
      end
  end
end
