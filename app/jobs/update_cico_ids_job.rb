# frozen_string_literal: true

class UpdateCicoIdsJob < ApplicationJob
  def perform(collection_id:, logger: Logger.new($stdout))
    collection = query_service.find_by(id: collection_id)
    Wayfinder.for(collection).members.each do |resource|
      next unless resource.local_identifier.present?
      id_switcher = IdSwitcher.new(resource.local_identifier)
      next unless id_switcher.updates?
      logger.info "Updating #{resource.id}'s local_identifier from #{resource.local_identifier} to #{id_switcher.new_array}"
      resource.local_identifier = id_switcher.new_array
      metadata_adapter.persister.save(resource: resource)
    end
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end
  delegate :query_service, to: :metadata_adapter

  class IdSwitcher
    attr_accessor :id_array

    def initialize(id_array)
      @id_array = id_array
    end

    def updates?
      id_array != new_array
    end

    def new_array
      @new_array ||= id_array.map { |id| id.sub(/^cico:/, "dcl:") }
    end
  end
end
