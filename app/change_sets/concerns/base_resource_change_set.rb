# frozen_string_literal: true
# A base mixin for resources that hold files
module BaseResourceChangeSet
  extend ActiveSupport::Concern

  included do
    def visibility=(visibility)
      super.tap do |_result|
        case visibility
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          self.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          self.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          self.read_groups = []
        end
      end
    end

    def apply_remote_metadata?
      source_metadata_identifier.present? && (!persisted? || refresh_remote_metadata == "1")
    end

    def apply_remote_metadata_directly?
      false
    end
  end
end
