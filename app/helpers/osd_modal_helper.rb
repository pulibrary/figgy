# frozen_string_literal: true
module OsdModalHelper
  include ::BlacklightHelper
  def osd_modal_for(resource)
    block = yield
    if !resource
      block
    else
      tag.span(block, class: "ignore-select", data: { modal_manifest: "#{ManifestBuilder::ManifestHelper.new.manifest_image_path(resource)}/info.json" })
    end
  rescue
    tag.span(block)
  end
end
