# frozen_string_literal: true
class PlumChangeSetPersister
  class Characterize
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :created_file_sets, :characterize?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless created_file_sets.present?
      created_file_sets.each do |file_set|
        next unless file_set.instance_of?(FileSet) && characterize?
        ::CharacterizationJob.perform_later(file_set.id.to_s)
      end
    end
  end
end
