# frozen_string_literal: true
class PlumChangeSetPersister
  attr_reader :metadata_adapter, :storage_adapter, :created_file_sets
  delegate :persister, :query_service, to: :metadata_adapter
  def initialize(metadata_adapter:, storage_adapter:, transaction: false)
    @metadata_adapter = metadata_adapter
    @storage_adapter = storage_adapter
    @transaction = transaction
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

  def with(metadata_adapter:)
    yield self.class.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter, transaction: true)
  end

  private

    def before_save(change_set:)
      apply_remote_metadata(change_set: change_set)
      create_files(change_set: change_set)
    end

    def after_save(change_set:, updated_resource:); end

    def before_delete(change_set:)
      clean_up_collection_associations(change_set: change_set) if change_set.resource.is_a?(Collection)
    end

    def apply_remote_metadata(change_set:)
      return unless change_set.respond_to?(:source_metadata_identifier)
      return unless change_set.apply_remote_metadata?
      attributes = RemoteRecord.retrieve(change_set.source_metadata_identifier).attributes
      blank_attributes.merge(attributes).each do |key, value|
        if change_set.model.respond_to?("#{key}=")
          change_set.model.__send__("#{key}=", value)
        end
      end
    end

    def clean_up_collection_associations(change_set:)
      resources = query_service.find_inverse_references_by(resource: change_set.resource, property: :member_of_collection_ids)
      resources.each do |resource|
        resource.member_of_collection_ids -= [change_set.id]
        persister.save(resource: resource)
      end
    end

    def create_files(change_set:)
      appender = FileAppender.new(storage_adapter: storage_adapter, persister: persister, files: files(change_set: change_set))
      @created_file_sets = appender.append_to(change_set.resource)
    end

    def after_commit
      return unless @created_file_sets
      @created_file_sets.each do |file_set|
        next unless file_set.instance_of?(FileSet)
        CharacterizationJob.perform_later(file_set.id.to_s)
      end
    end

    def files(change_set:)
      change_set.try(:files) || []
    end

    def blank_attributes
      Hash[
        PlumSchema.imported_schema.map do |key|
          [key, nil]
        end
      ]
    end
end
