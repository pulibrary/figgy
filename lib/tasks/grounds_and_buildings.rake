# frozen_string_literal: true
require "csv"

namespace :sip do
  desc "Update finding-aid components with members"
  task update_components: :environment do
    collection_id = ENV["COLL"]
    table_path = ENV["TABLE"]
    abort "usage: rake sip:update_components COLL=collid TABLE=path_to_table" unless collection_id and File.exist?(table_path)

    @logger = Logger.new(STDOUT)
    @logger.info "updating components of collection #{collection_id} from #{table_path}"

    table = CSV.parse(File.read(table_path), headers: true)
    csp = ScannedResourcesController.change_set_persister

    components = table.collect { |i| i['componentID'] }.uniq
    components.each do |component|
      @logger.info "updating #{collection_id}_#{component}"
      component_resource = csp.query_service.custom_queries.find_by_property(
      property: :source_metadata_identifier,
      value: "#{collection_id}_#{component}"
      ).first

      if component_resource.nil?
        component_resource = ScannedResource.new(
          source_metadata_identifier: "#{collection_id}_#{component}")
      end
      
      component_resource_change_set = ChangeSet.for component_resource

      children = table.select { |row| row['componentID'] == component }.map {
        |i| i["Figgy URL"].match(/^.*catalog\//).post_match }

      component_resource_change_set.validate(member_ids: children)
      csp.save(change_set: component_resource_change_set)
    end
  end
end
