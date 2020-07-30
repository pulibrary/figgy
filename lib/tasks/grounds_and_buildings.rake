# frozen_string_literal: true
require "csv"

namespace :sip do
  desc "Update finding-aid components with members"
  task update_components: :environment do
    collection_id = ENV["COLL"]
    table_path = ENV["TABLE"]
    abort "usage: rake sip:update_components COLL=collid TABLE=path_to_table" unless collection_id && File.exist?(table_path)

    @logger = Logger.new(STDOUT)
    @logger.info "updating components of collection #{collection_id} from #{table_path}"

    table = CSV.parse(File.read(table_path), headers: true)
    csp = ScannedResourcesController.change_set_persister

    components = table.collect { |i| i["componentID"] }.uniq
    components.each do |component|
      @logger.info "updating #{collection_id}_#{component}"
      component_resource = csp.query_service.custom_queries.find_by_property(
        property: :source_metadata_identifier,
        value: "#{collection_id}_#{component}"
      ).first

      if component_resource.nil?
        component_resource = ScannedResource.new(
          source_metadata_identifier: "#{collection_id}_#{component}"
        )
      end

      component_resource_change_set = ChangeSet.for component_resource

      children = table.select { |row| row["componentID"] == component }.map do |i|
        i["Figgy URL"].match(/^.*catalog\//).post_match
      end

      component_resource_change_set.validate(member_ids: children)
      csp.save(change_set: component_resource_change_set)
    end
  end

  desc "Update images with additional metadata"
  task update_image_metadata: :environment do
    table_path = ENV["TABLE"]
    abort "usage: rake sip:update_image_metadata TABLE=path_to_table" unless File.exist?(table_path)

    @logger = Logger.new(STDOUT)
    @logger.info "updating metadata of figgy objects in #{table_path}"

    table = CSV.parse(File.read(table_path), headers: true)
    metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
    qs = metadata_adapter.query_service
    csp = ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)

    table.each do |row|
      figgy_id = row["Figgy URL"].match(/^.*catalog\//).post_match
      # get the resource
      resource = qs.find_by(id: figgy_id)
      # get changeset for resource
      cs = ChangeSet.for(resource)
      # update resource and changeset with field values; date is special
      if row["End Date"]
        cs.validate(date:
                      DateRange.new(start: row["Date"], end: row["End Date"], approximate: row["Approximate"] == "approximate"))
      else
        cs.validate(date: row["Date"])
      end
      cs.validate(title: row["Title"],
                  subject: row["Subject"],
                  photographer: row["Photographer"],
                  description: row["Description"],
                  location: row["Location"])
      csp.save(change_set: cs)
    end
  end
end
