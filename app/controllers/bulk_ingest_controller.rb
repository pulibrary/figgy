# frozen_string_literal: true
class BulkIngestController < ApplicationController
  def self.metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def self.storage_adapter
    Valkyrie.config.storage_adapter
  end

  def self.change_set_persister
    @change_set_persister ||= ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter)
  end

  def self.change_set_class
    DynamicChangeSet
  end

  def show
    authorize! :create, resource_class
    @collections = collections
    @resource_class = resource_class
    @states = workflow_states
    @visibility = ControlledVocabulary.for(:visibility).all
  end

  def browse_everything_files
    if browse_everything_uploads.empty? || first_upload.containers.empty?
      flash[:alert] = "Please select some files to ingest."
      return redirect_to bulk_ingest_show_path
    end

    if selected_cloud_files?
      self.class.change_set_persister.buffer_into_index do |buffered_changeset_persister|
        if multi_volume_work?
          ingest_multi_volume_works(buffered_changeset_persister)
        else
          ingest_works(buffered_changeset_persister)
        end
      end
    else
      IngestFolderJob.perform_later(directory: selected_folder_root_path, file_filter: nil, class_name: resource_class_name, **attributes)
    end

    redirect_to root_url, notice: "Batch Ingest of #{resource_class.human_readable_type.pluralize} started"
  end

  private

    def attributes
      {
        member_of_collection_ids: collections_param,
        source_metadata_identifier: source_metadata_id_from_path,
        state: params[:workflow][:state],
        visibility: params[:visibility]
      }
    end

    def source_metadata_id_from_path
      base_path if valid_remote_identifier?(base_path)
    end

    def browse_everything_params
      return {} unless params.key?("browse_everything")
      @browse_everything_params ||= params["browse_everything"]
    end

    def browse_everything_uploads
      return [] unless browse_everything_params.key?("uploads")
      @browse_everything_uploads ||= browse_everything_params["uploads"]
    end

    def find_upload(upload_id)
      uploads = BrowseEverything::Upload.find_by(uuid: upload_id)
      uploads.first
    end

    def new_uploads
      @new_uploads ||= begin
                         browse_everything_uploads.map do |upload_id|
                           find_upload(upload_id)
                         end
                       end
    end

    def ingest_multi_volume_works(change_set_persister)
      new_uploads.each do |upload|
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
      new_uploads.each do |upload|
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

    def first_upload
      @first_upload ||= new_uploads.first
    end

    def selected_cloud_files?
      !first_upload.provider.is_a?(BrowseEverything::Provider::FileSystem)
    end

    def selected_folder_root_path
      paths = first_upload.containers.map { |container| container.id.gsub("file://", "") }
      sorted_paths = paths.sort_by(&:length)
      sorted_paths.first
    end

    def base_path
      File.basename(selected_folder_root_path)
    end

    # Determines whether or not the string encodes a bib. ID or a PULFA ID
    # See SourceMetadataIdentifierValidator#validate
    # @param [String] value
    # @return [Boolean]
    def valid_remote_identifier?(value)
      RemoteRecord.valid?(value) && RemoteRecord.retrieve(value).success?
    rescue URI::InvalidURIError
      false
    end

    def collections
      collection_decorators = query_service.find_all_of_model(model: Collection).map(&:decorate)
      collection_decorators.to_a.collect { |c| [c.title, c.id.to_s] }
    end

    def collections_param
      params[:collections] || []
    end

    def multi_volume_work?
      params[:mvw] == "true"
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end

    def resource_class
      resource_class_name.constantize
    end

    def resource_class_name
      params[:resource_type].classify
    end

    def build_resource
      resource_class.new
    end

    def build_change_set(attrs)
      change_set = DynamicChangeSet.new(build_resource)
      change_set.validate(**attrs)
      change_set
    end

    def workflow_states
      workflow_class.aasm.states.map { |s| s.name.to_s }
    end

    def workflow_class
      @workflow_class ||= DynamicChangeSet.new(resource_class.new).workflow_class
    end
end
