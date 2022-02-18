# frozen_string_literal: true

# A base mixin for resources that hold files
module VisibilityProperty
  extend ActiveSupport::Concern

  included do
    # override this property to define a different default
    property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    property :set_visibility_by_date, virtual: true, multiple: false

    def set_visibility_by_date?
      set_visibility_by_date == "1"
    end

    def visibility=(visibility)
      super.tap do |_result|
        case visibility
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          self.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          self.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
        when ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_READING_ROOM
          self.read_groups = [::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_READING_ROOM]
        when ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS
          self.read_groups = [::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_ON_CAMPUS]
        when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          self.read_groups = []
        end
      end
    end
  end
end
