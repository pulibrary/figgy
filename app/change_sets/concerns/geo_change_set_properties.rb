# frozen_string_literal: true
module GeoChangeSetProperties
  extend ActiveSupport::Concern

  included do
    property :coverage, multiple: false, required: false
    property :creator, multiple: false, required: false
    property :description, multiple: true, required: false, default: []
    property :identifier, multiple: false, required: false
    property :issued, multiple: false, required: false
    property :language, multiple: false, required: false
    property :provenance, multiple: false, required: false, default: "Princeton"
    property :publisher, multiple: false, required: false
    property :spatial, multiple: true, required: false, default: []
    property :subject, multiple: false, required: false
    property :temporal, multiple: true, required: false, default: []
    property :cartographic_scale, multiple: false, required: false
    property :cartographic_projection, multiple: false, required: false
  end
end
