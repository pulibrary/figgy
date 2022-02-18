# frozen_string_literal: true

class ChangeSetPersister
  class ApplyVisibilityByDate
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.try(:set_visibility_by_date?)
      return unless date_object
      change_set.validate(visibility: calculated_visibility, rights_statement: calculated_rights_statement)
      change_set.sync
      change_set
    end

    private

      def date
        Array.wrap(change_set.resource.primary_imported_metadata.created).first
      end

      def date_object
        return unless date
        Time.zone.parse(date)
      rescue
        Rails.logger.warn("Unable to parse created date: #{change_set.resource.primary_imported_metadata.created}")
        nil
      end

      def limit_date
        Time.zone.parse("1924-01-01T00:00:00Z")
      end

      def public_access?
        date_object < limit_date
      end

      def calculated_visibility
        if public_access?
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        else
          Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        end
      end

      def calculated_rights_statement
        if public_access?
          RightsStatements.no_known_copyright.to_s
        else
          RightsStatements.in_copyright.to_s
        end
      end
  end
end
