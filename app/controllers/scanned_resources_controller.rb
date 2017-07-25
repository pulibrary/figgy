# frozen_string_literal: true
class ScannedResourcesController < ApplicationController
  include Valhalla::ResourceController
  self.change_set_class = ScannedResourceChangeSet
  self.resource_class = ScannedResource
  self.adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
end
