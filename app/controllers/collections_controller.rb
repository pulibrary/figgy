# frozen_string_literal: true
require "csv"

class CollectionsController < ResourcesController
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

  def around_delete_action
    # Only allow deleting empty collections. Avoids difficulty of restoring a
    # full collection from preservation and supporting restoring accidentally
    # deleted collections.
    if Wayfinder.for(@change_set.resource).members_count.positive?
      flash[:alert] = "Unable to delete a collection with members. Please transfer membership to another collection before deleting this collection."
      redirect_to solr_document_path(@change_set.resource.id.to_s)
    else
      yield
    end
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
