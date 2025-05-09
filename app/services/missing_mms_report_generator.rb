# frozen_string_literal: true

class MissingMmsReportGenerator < ReferencedMmsReportGenerator
  private

    def resources
      @resources ||= collection_members.select { |resource| resource.source_metadata_identifier.blank? }
    end
end
