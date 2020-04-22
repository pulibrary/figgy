# frozen_string_literal: true

# Ingests directories of files queued for upload by BrowseEverything
# This class was extracted from BulkIngestController and is covered by its specs
class BulkCloudIngester
  attr_reader :change_set_persister, :multi_volume_work, :upload_sets, :resource_class

  # @param change_set_persister [ChangeSetPersister]
  # @param multi_volume_work [Boolean]
  # @param upload_sets Array<[BrowseEverything::Upload]>
  # @resource_class [String]
  def initialize(change_set_persister:, multi_volume_work:, upload_sets:, resource_class:)
    @change_set_persister = change_set_persister
    @multi_volume_work = multi_volume_work
    @upload_sets = upload_sets
    @resource_class = resource_class
  end

  def ingest
    return false unless selected_cloud_files?
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      upload_sets.each do |upload|
        UploadSetPersister.new(buffered_changeset_persister, resource_class: resource_class).save(upload, mvw: multi_volume_work)
      end
    end
    true
  end

  private

    def selected_cloud_files?
      !upload_sets.first.provider.is_a?(BrowseEverything::Provider::FileSystem)
    end

    class UploadSetPersister
      attr_reader :change_set_persister, :resource_class
      attr_accessor :directories_lookup, :parent_containers
      def initialize(change_set_persister, resource_class:)
        @change_set_persister = change_set_persister
        @resource_class = resource_class
        @directories_lookup = Hash.new([])
        @parent_containers = []
      end

      def save(upload, mvw:)
        files_lookup = pending_upload_files(upload)

        upload.containers.each do |container|
          save_container(container, files_lookup)
        end

        save_parents if mvw
      end

      def save_container(container, files_lookup)
        # Create the volume work if the container has files
        if files_lookup.key?(container.id)
          files = files_lookup[container.id]
          member_change_set = build_change_set(title: container.name, pending_upload_files: files, files: files)

          persisted = change_set_persister.save(change_set: member_change_set)

          parent_id = container.parent_id
          if parent_id
            directories_lookup[parent_id] += [persisted]
          end
        # if the container only had directories, it's a MVW parent work
        else
          # create these later; we don't know their members until we're done
          # iterating through the containers
          parent_containers << container
        end
      end

      def save_parents
        # Create MVW parent work/s
        parent_containers.each do |container|
          members = directories_lookup[container.id]
          member_ids = members.map(&:id)
          parent_name = container.name

          parent_change_set = build_change_set(title: parent_name, member_ids: member_ids)
          change_set_persister.save(change_set: parent_change_set)
        end
      end

      # Create a PendingUpload for each file to be uploaded,
      #   add it to a lookup table with container id as its key
      def pending_upload_files(upload)
        file_tree = Hash.new([])
        upload.files.each do |upload_file|
          new_pending_upload = PendingUpload.new(
            id: SecureRandom.uuid,
            upload_id: upload.id,
            upload_file_id: upload_file.id
          )

          if new_pending_upload.in_container?
            file_tree[upload_file.container_id] += [new_pending_upload]
          end
        end
        file_tree
      end

      def build_change_set(attrs)
        change_set = DynamicChangeSet.new(build_resource)
        change_set.validate(**attrs)
        change_set
      end

      def build_resource
        resource_class.new
      end
    end
end
