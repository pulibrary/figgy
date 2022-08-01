# frozen_string_literal: true
module OsdModalHelper
  include ::BlacklightHelper
  def osd_modal_for(resource)
    if !resource
      yield
    else
      tag.span(class: "ignore-select", data: { modal_manifest: "#{ManifestBuilder::ManifestHelper.new.manifest_image_path(resource)}/info.json" }) do
        yield
      end
    end
  rescue
    tag.span do
      yield if block_given?
    end
  end
end
