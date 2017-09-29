# frozen_string_literal: true
# A base mixin for resources that hold files
module RemoteMetadataProperty
  extend ActiveSupport::Concern

  included do
    property :refresh_remote_metadata, virtual: true, multiple: false

    def apply_remote_metadata?
      source_metadata_identifier.present? && (!persisted? || refresh_remote_metadata == "1")
    end

    def apply_remote_metadata_directly?
      false
    end
  end
end
