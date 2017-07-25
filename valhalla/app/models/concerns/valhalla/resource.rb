# frozen_string_literal: true
module Valhalla
  class Resource < Valkyrie::Resource
    def self.human_readable_type
      default = @_human_readable_type || name.demodulize.titleize
      I18n.translate("valhalla.models.#{new.model_name.i18n_key}", default: default)
    end

    def self.human_readable_type=(val)
      @_human_readable_type = val
    end

    def human_readable_type
      self.class.human_readable_type
    end
  end
end
