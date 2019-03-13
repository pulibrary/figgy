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
  end

  def browse_everything_files
    if selected_files.empty?
      flash[:alert] = "Please select some files to ingest."
      return redirect_to bulk_ingest_show_path
    end

    if selected_cloud_files?
      persisted_ids = {}
      file_paths

      if multi_volume_work?
        self.class.change_set_persister.buffer_into_index do |buffered_changeset_persister|
          persisted_members = []

          # Only append one file as a FileSet to one member of one parent until browse-everything can provide links to parent resource IDs
          selected_files.each do |selected_file|
            member_change_set = build_change_set(title: selected_file.file_name, pending_uploads: [selected_file])
            persisted_members << buffered_changeset_persister.save(change_set: member_change_set)
            persisted_ids[persisted_members.last.id.to_s] = [selected_file.id.to_s]
          end

          parent_change_set = build_change_set(title: selected_files.first.file_name, member_ids: persisted_members.map(&:id))
          buffered_changeset_persister.save(change_set: parent_change_set)
        end
      else
        # Only append one file as a FileSet to one resource until browse-everything can provide links to parent resource IDs
        self.class.change_set_persister.buffer_into_index do |buffered_changeset_persister|
          selected_files.each do |selected_file|
            change_set = build_change_set(title: selected_file.file_name, pending_uploads: [selected_file])
            persisted = buffered_changeset_persister.save(change_set: change_set)
            persisted_ids[persisted.id.to_s] = [selected_file.id.to_s]
          end
        end
      end

      # Use the IDs of the newly-persisted resources to attached the cloud files as FileSets
      persisted_ids.each do |persisted_id, selected_file_ids|
        BrowseEverythingIngestJob.perform_later(persisted_id, self.class.to_s, selected_file_ids)
      end
    elsif file_paths.max_parent_path_depth == 1
      IngestFolderJob.perform_later(directory: parent_path.to_s, file_filter: nil, class_name: resource_class_name, **attributes)

    else
      IngestFoldersJob.perform_later(directory: parent_path.to_s, file_filter: nil, class_name: resource_class_name, **attributes)
    end

    redirect_to root_url, notice: "Batch Ingest of #{resource_class.human_readable_type.pluralize} started"
  end

  private

    def attributes
      {
        member_of_collection_ids: collections_param,
        state: params[:workflow][:state],
        visibility: params[:visibility]
      }
    end

    def collections
      collection_decorators = query_service.find_all_of_model(model: Collection).map(&:decorate)
      collection_decorators.to_a.collect { |c| [c.title, c.id.to_s] }
    end

    def collections_param
      params[:collections] || []
    end

    def file_paths
      @file_paths ||= BrowseEverythingFilePaths.new(selected_files_param)
    end

    def multi_volume_work?
      params[:mvw] == "true"
    end

    def parent_path
      path = file_paths.parent_path
      if multi_volume_work? && file_paths.max_parent_path_depth == 2
        # Single multi-volume works need a parent path one level above to ingest properly.
        # Otherwise, they are indistinguishable from multiple singe-volume works.
        File.dirname(path)
      else
        path
      end
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

    def selected_files_param
      return {} unless params.key?(:selected_files) && !params[:selected_files].empty?
      params[:selected_files].to_unsafe_h
    end

    def selected_cloud_files?
      values = selected_files_param.map { |_index, file| /^https?\:/ =~ file["url"] }
      values.reduce(:|)
    end

    def selected_files
      @selected_files ||= selected_files_param.values.map do |x|
        auth_header_values = x.delete("auth_header")
        auth_header = JSON.generate(auth_header_values)
        PendingUpload.new(x.symbolize_keys.merge(id: SecureRandom.uuid, created_at: Time.current.utc.iso8601, auth_header: auth_header))
      end
    end

    def workflow_states
      workflow_class.aasm.states.map { |s| s.name.to_s }
    end

    def workflow_class
      @workflow_class ||= DynamicChangeSet.new(resource_class.new).workflow_class
    end
end
