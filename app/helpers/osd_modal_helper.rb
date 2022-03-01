# frozen_string_literal: true
module OsdModalHelper
  include ::BlacklightHelper
  def osd_modal_for(resource, &block)
    if !resource
      yield
    else
      tag.span class: "ignore-select", data: { modal_manifest: "#{ManifestBuilder::ManifestHelper.new.manifest_image_path(resource)}/info.json" }, &block
    end
  rescue
    tag.span
  end
end
