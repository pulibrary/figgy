# frozen_string_literal: true
module Valhalla
  module ContextualPathHelper
    def contextual_path(child, parent)
      ContextualPath.new(child: child, parent_id: parent.try(:id))
    end
  end
end
