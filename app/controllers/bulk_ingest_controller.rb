# frozen_string_literal: true
# Supported!!:
#
# Many Single Volumes
# - Lapidus
#   - 123456
#     page1
#   - 1234567
#     page1

# Many MVW
# - Lapidus
#   - 123456
#     - vol1
#       - page1
#     - vol2
#       - page2
#   - 1234567
#     - vol1
#       - page1
#     - vol2
#       - page2

# Single MVW
# - Stuff
#   - 123456
#     - vol1
#       page1
#     - vol2
#       page1

# Not supported!

#  - 123456
#    page1
#  - 1234567
#    page1

# 802310
#  - vol1
#    - page1
#  - vol2
#    - page1
# 123456
#  - vol1
#    - page1
#  - vol2
#    - page1

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
    unless files_to_upload?
      flash[:alert] = "Please select some files to ingest."
      return redirect_to bulk_ingest_show_path
    end
    if cloud_ingester.valid?
      browse_everything_uploads.each do |upload_id|
        BrowseEverything::UploadJob.perform_now(upload_id: upload_id)
      end
    end
    cloud_ingester.queue_ingest || local_ingester.ingest

    redirect_to root_url, notice: "Batch Ingest of #{resource_class.human_readable_type.pluralize} started"
  end

  private

    def cloud_ingester
      BulkCloudIngester.new(
        change_set_persister: self.class.change_set_persister,
        upload_sets: upload_sets,
        resource_class: resource_class
      )
    end

    def local_ingester
      BrowseEverythingLocalIngester.new(
        upload_sets: upload_sets,
        resource_class_name: resource_class_name,
        attributes: attributes
      )
    end

    def files_to_upload?
      upload_sets.any? && upload_sets.first.containers.any?
    end

    def attributes
      {
        member_of_collection_ids: collection_ids,
        state: params[:workflow][:state],
        visibility: params[:visibility]
      }
    end

    def collections
      collection_decorators = query_service.find_all_of_model(model: Collection).map(&:decorate)
      collection_decorators.to_a.collect { |c| [c.title, c.id.to_s] }
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

    def workflow_states
      workflow_class.aasm.states.map { |s| s.name.to_s }
    end

    def workflow_class
      @workflow_class ||= DynamicChangeSet.new(resource_class.new).workflow_class
    end

    def collection_ids
      params[:collections] || []
    end

    def upload_sets
      @upload_sets ||= begin
        browse_everything_uploads.map do |upload_id|
          find_upload(upload_id)
        end
      end
    end

    def browse_everything_uploads
      return [] unless browse_everything_params.key?("uploads")
      browse_everything_params["uploads"]
    end

    def browse_everything_params
      return {} unless params.key?("browse_everything")
      params["browse_everything"]
    end

    def find_upload(upload_id)
      BrowseEverything::Upload.find_by(uuid: upload_id).first
    end
end
