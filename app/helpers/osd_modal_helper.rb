# frozen_string_literal: true

module OsdModalHelper
  include ::BlacklightHelper
  def osd_modal_for(resource, &block)
    if !resource
      yield
    else
      content_tag :span, class: "ignore-select", data: {modal_manifest: "#{ManifestBuilder::ManifestHelper.new.manifest_image_path(resource)}/info.json"}, &block
    end
  rescue
    content_tag :span
  end
end
