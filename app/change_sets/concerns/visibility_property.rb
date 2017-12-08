# frozen_string_literal: true
# A base mixin for resources that hold files
module VisibilityProperty
  extend ActiveSupport::Concern

  included do
    # override this property to define a different default
    property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC

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
  end
end
