# frozen_string_literal: false

module MetadataFormHelper
  def form_title(params)
    controller_name = params["controller"]
    model_name = controller_name.singularize.downcase
    action = params["action"].capitalize
    action = "New" if action == "Create"

    model_params = params[model_name]

    if model_params && form_custom_title(model_params)
      "#{action} #{model_params["change_set"].humanize.singularize.downcase} resource"
    elsif form_custom_title(params)
      "#{action} #{params["change_set"].humanize.singularize.downcase} resource"
    else
      "#{action} #{model_name.humanize.downcase}"
    end
  end

  def form_custom_title(params)
    params["change_set"].present?
  end

  # Determine whether or not a resource has parents
  # @param resource [Valkyrie::Resource]
  # @return [TrueClass, FalseClass]
  def resource_has_parents?(resource, params)
    if !resource.persisted?
      params[:parent_id]
    else
      resource.decorate.respond_to?(:decorated_parent) && !resource.decorate.decorated_parent.nil?
    end
  end
end
