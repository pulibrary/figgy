# frozen_string_literal: true
module GeoChangeSetProperties
  extend ActiveSupport::Concern

  included do
    property :coverage, multiple: false, required: false
    property :creator, multiple: false, required: false
    property :description, multiple: true, required: false, default: []
    property :held_by, multiple: false, required: false, default: "Princeton"
    property :identifier, multiple: false, required: false
    property :issued, multiple: false, required: false
    property :language, multiple: false, required: false
    property :provenance, multiple: false, required: false
    property :publisher, multiple: false, required: false
    property :spatial, multiple: true, required: false, default: []
    property :subject, multiple: true, required: false, default: []
    property :temporal, multiple: true, required: false, default: []
    property :cartographic_scale, multiple: false, required: false
    property :cartographic_projection, multiple: false, required: false
    property :wms_url, multiple: false, required: false
    property :wfs_url, multiple: false, required: false
    property :layer_name, multiple: false, required: false
  end
end
