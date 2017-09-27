# frozen_string_literal: true
class ValkyrieShowPresenter < ::Blacklight::ShowPresenter
  def heading
    document.decorated_resource.heading
  end
end
