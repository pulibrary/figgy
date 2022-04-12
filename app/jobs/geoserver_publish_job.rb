# frozen_string_literal: true
class GeoserverPublishJob < ApplicationJob
  queue_as :high

  def perform(operation:, resource_id:)
    @resource = query_service.find_by(id: resource_id)

    case operation
    when "delete"
      geo_members.each { |m| GeoserverPublishService.new(resource: m).delete }
    when "derivatives_create"
      GeoserverPublishService.new(resource: @resource).create
    when "derivatives_delete"
      GeoserverPublishService.new(resource: @resource).delete
    when "update"
      geo_members.each { |m| GeoserverPublishService.new(resource: m).update }
    end
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
  end

  def geo_members
    @resource.decorate.geo_members.select do |member|
      member.derivative_file.present?
    end
  end
end
