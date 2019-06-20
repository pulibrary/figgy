# frozen_string_literal: true
require "csv"

class CollectionsController < ApplicationController
  include ResourceController
  include TokenAuth
  include BrowseEverything::Parameters
  self.change_set_class = DynamicChangeSet
  self.resource_class = Collection
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  def manifest
    @resource = find_resource(params[:id])
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource, nil, current_ability).build
      end
    end
  end

  def index_manifest
    @resource = IndexCollection.new
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(@resource).build
      end
    end
  end

  def ark_report
    collection = query_service.find_by(id: params[:id])
    authorize! :read, collection
    @collection = collection.decorate
    @records = ark_report_records(@collection)
    respond_to do |format|
      format.html
      format.csv do
        send_data ark_csv(@records),
                  filename: "ark-report-#{@collection.title.parameterize}-#{Time.zone.today}.csv"
      end
    end
  end

  def change_set_class
    if params[:change_set].present? || (resource_params && resource_params[:change_set].present?)
      DynamicChangeSet.class_from_param(params[:change_set] || resource_params[:change_set])
    else
      DynamicChangeSet
    end
  end

  def resource
    find_resource(params[:id])
  end

  def change_set
    change_set_class.new(resource).prepopulate!
  end

  def file_manager
    @change_set = change_set_class.new(find_resource(params[:id])).prepopulate!
    authorize! :file_manager, @change_set.resource

    collection_members = @change_set.resource.decorate.members
    resource_members = collection_members.reject { |x| x.decorate.file_sets.empty? }
    file_sets = resource_members.map { |x| x.decorate.file_sets }
    @children = file_sets.flatten.map do |x|
      DynamicChangeSet.new(x).prepopulate!
    end
  end

  def selected_directories
    file_values = params.fetch(:selected_files, [])
    file_extensions = file_values.values
    dir_names = file_extensions.map do |x|
      pathname = x["url"].gsub("file://", "")
      File.dirname(pathname)
    end
    dir_names.uniq!
    child_dirs = []
    dir_names.each do |x|
      child_dirs += dir_names.select { |y| y != x && y.include?(x) }
    end
    dir_names - child_dirs
  end

  # Resources that allow uploads will use these browse everything methods
  def browse_everything_files
    selected_directories.each do |directory|
      IngestArchivalMediaBagJob.perform_now(
        collection_component: change_set.resource.source_metadata_identifier.first,
        bag_path: directory,
        user: current_user
      )
    end
    flash[:notice] = "Archival bags have been enqueued for ingestion in this collection." unless selected_directories.empty?

    redirect_to solr_document_path(id: resource.id)
  end

  private

    def ark_report_records(collection)
      collection.members.map do |resource|
        [resource.source_metadata_identifier&.first,
         resource.identifier&.first,
         helpers.manifest_url(resource)]
      end
    end

    def ark_csv(records)
      CSV.generate(headers: true) do |csv|
        csv << ["source_metadata_id", "ark", "manifest_url"]
        records.each do |record|
          csv << record
        end
      end
    end
end
