# frozen_string_literal: true
class BulkIngestController < ApplicationController
  def show
    authorize! :create, resource_class
    @states = workflow_states
    @resource_class = resource_class
  end

  def browse_everything_files
    if file_paths.parent_path_contains_all_files?
      IngestFolderJob.perform_later(directory: file_paths.parent_path.to_s, file_filter: nil, class_name: resource_class_name, **attributes)
    else
      IngestFoldersJob.perform_later(directory: file_paths.parent_path.to_s, file_filter: nil, class_name: resource_class_name, **attributes)
    end

    redirect_to root_url, notice: "Batch Ingest of #{resource_class.human_readable_type.pluralize} started"
  end

  private

    def attributes
      {
        state: params[:workflow][:state],
        visibility: params[:visibility]
      }
    end

    def file_paths
      @file_paths ||= BrowseEverythingFilePaths.new(selected_files_param)
    end

    def resource_class
      resource_class_name.constantize
    end

    def resource_class_name
      params[:resource_type].classify
    end

    def selected_files_param
      params[:selected_files].to_unsafe_h
    end

    def workflow
      WorkflowRegistry.workflow_for(resource_class)
    end

    def workflow_states
      workflow.aasm.states.map { |s| s.name.to_s }
    end
end
