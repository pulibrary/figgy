# frozen_string_literal: true
module Valhalla
  module ApplicationHelper
    def visibility_badge(value)
      Valhalla::PermissionBadge.new(value).render
    end
  end
end
