# frozen_string_literal: true
class ChangeSetPersister
  class Characterize
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :characterize?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return if created_file_sets.blank?
      created_file_sets.each do |file_set|
        next unless characterize?
        if file_set.instance_of?(FileSet)
          ::CharacterizationJob.set(queue: change_set_persister.queue).perform_later(file_set.id.to_s)
        elsif change_set.resource.try(:preservation_targets)&.include?(file_set) && file_set.checksum.blank?
          # Attaching a resource that we need to preserve, so generate
          # checksums.
          GenerateChecksumJob.perform_later(post_save_resource.id.to_s)
        end
      end
    end

    def created_file_sets
      change_set.try(:created_file_sets) || []
    end
  end
end
