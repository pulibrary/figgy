# frozen_string_literal: true
class ChangeSetPersister
  # When an OCR language is set it propagates to child resources.
  class PropagateOCRLanguage
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, to: :change_set_persister

    # Constructor
    # @param change_set_persister [ChangeSetPersister]
    # @param change_set [Valkyrie::ChangeSet]
    # @param post_save_resource [Valkyrie::Resource]
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    # Execute the handler
    def run
      return unless change_set.changed?(:ocr_language)
      members.each do |member|
        next unless member.respond_to?(:ocr_language)
        member_change_set = ChangeSet.for(member)
        member_change_set.validate(ocr_language: change_set.ocr_language)
        change_set_persister.save(change_set: member_change_set)
      end
    end

    def members
      @members ||= Wayfinder.for(change_set.resource).try(:members)
    end
  end
end
