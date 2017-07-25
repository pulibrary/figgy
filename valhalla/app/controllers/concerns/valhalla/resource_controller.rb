# frozen_string_literal: true
module Valhalla
  module ResourceController
    extend ActiveSupport::Concern
    included do
      class_attribute :change_set_class, :resource_class, :adapter
    end

    def new
      @change_set = change_set_class.new(resource_class.new).prepopulate!
      authorize! :create, resource_class
    end

    def _prefixes
      @_prefixes ||= super + ['valhalla/base']
    end
  end
end
