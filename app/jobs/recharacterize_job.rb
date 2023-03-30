# frozen_string_literal: true
class RecharacterizeJob < ApplicationJob
  def perform(id)
    @metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
    r = @metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(id)).decorate

    logger.info "Recharacterizing #{id}"

    if r.is_a? FileSet
      recharacterize([r])
    else
      recharacterize(r.decorated_file_sets)
      r.volumes.each do |vol|
        logger.info "Recharacterizing volume #{vol.id}"
        recharacterize(vol.decorated_file_sets)
      end
    end
    logger.info "Recharacterized #{id}"
  end

  def recharacterize(file_sets)
    file_sets.each do |file_set|
      @metadata_adapter.persister.buffer_into_index do |buffered_adapter|
        Valkyrie::Derivatives::FileCharacterizationService.for(file_set: file_set, persister: buffered_adapter.persister).characterize
      end
    end
  end
end
