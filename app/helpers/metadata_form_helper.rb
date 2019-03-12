# frozen_string_literal: false
module MetadataFormHelper
  def form_title(params)
    if form_custom_title(params)
      "#{params['action'].capitalize} #{params['change_set'].humanize.singularize.downcase} resource"
    else
      "#{params['action'].capitalize} #{params['controller'].humanize.singularize.downcase}"
    end
  end

  def form_custom_title(params)
    params["change_set"].present?
  end
end
