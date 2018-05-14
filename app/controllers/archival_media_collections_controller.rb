# frozen_string_literal: true

class ArchivalMediaCollectionsController < CollectionsController
  self.resource_class = ArchivalMediaCollection

  def ark_report
    collection = query_service.find_by(id: params[:id])
    @resources = collection.decorate.media_resources
    respond_to do |format|
      format.html
      format.csv do
        send_data to_csv(@resources, fields: { identifier: "ark", source_metadata_identifier: "component_id" }),
                  filename: "ark-report-#{collection.source_metadata_identifier.first}-#{Time.zone.today}.csv"
      end
    end
  end

  private

    def to_csv(records, fields:)
      CSV.generate(headers: true) do |csv|
        csv << fields.map { |_k, v| v }
        records.each do |record|
          csv << fields.map { |k, _v| Array.wrap(record.send(k)).first }
        end
      end
    end
end
