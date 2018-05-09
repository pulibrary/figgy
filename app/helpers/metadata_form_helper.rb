# frozen_string_literal: false
module MetadataFormHelper
  def form_title(params)
    "#{params['action'].capitalize} #{params['controller'].humanize.singularize.downcase}"
  end
end
