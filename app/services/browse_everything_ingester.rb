# frozen_string_literal: true

class BrowseEverythingIngester
  attr_reader :change_set_persister, :multi_volume_work, :uploads, :resource_class
  def initialize(change_set_persister:, multi_volume_work:, uploads:, resource_class:)
    @change_set_persister = change_set_persister
    @multi_volume_work = multi_volume_work
    @uploads = uploads
    @resource_class = resource_class
  end

  def ingest_from_cloud
    return false unless selected_cloud_files?
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      if multi_volume_work
        ingest_multi_volume_works(buffered_changeset_persister)
      else
        ingest_works(buffered_changeset_persister)
      end
    end
    true
  end

  private

    def selected_cloud_files?
      !uploads.first.provider.is_a?(BrowseEverything::Provider::FileSystem)
    end

    def ingest_multi_volume_works(change_set_persister)
      uploads.each do |upload|
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

        directory_tree = {}
        parent_containers = []
        upload.containers.each do |container|
          # Are there files for this container?
          if file_tree.key?(container.id)
            # Create the volume work
            children = file_tree[container.id]
            volume_name = container.name
            member_change_set = build_change_set(title: volume_name, pending_uploads: children, files: children)

            persisted = change_set_persister.save(change_set: member_change_set)

            parent_id = container.parent_id
            if parent_id
              members = directory_tree[parent_id] || []
              directory_tree[parent_id] = members + [persisted]
            end
          else
            parent_containers << container
          end
        end

        parent_containers.each do |container|
          # If not, create a parent work
          members = directory_tree[container.id] || []
          member_ids = members.map(&:id)
          parent_name = container.name

          parent_change_set = build_change_set(title: parent_name, member_ids: member_ids)
          change_set_persister.save(change_set: parent_change_set)
        end
      end
    end

    def ingest_works(change_set_persister)
      uploads.each do |upload|
        file_tree = {}
        upload.files.each do |upload_file|
          new_pending_upload = PendingUpload.new(
            id: SecureRandom.uuid,
            upload_id: upload.id,
            upload_file_id: upload_file.id
          )

          if new_pending_upload.in_container?
            pending_uploads = file_tree[upload_file.container_id] || []
            file_tree[upload_file.container_id] = pending_uploads + [new_pending_upload]
          end
        end

        upload.containers.each do |container|
          # Are there files for this container?
          next unless file_tree.key?(container.id)
          # Create the volume work
          children = file_tree[container.id]
          volume_name = container.name
          member_change_set = build_change_set(title: volume_name, pending_uploads: children, files: children)

          change_set_persister.save(change_set: member_change_set)
        end
      end
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
