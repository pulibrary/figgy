# frozen_string_literal: true
module Valhalla
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
