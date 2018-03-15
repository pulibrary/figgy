# frozen_string_literal: true
module BagValidation
  extend ActiveSupport::Concern

  included do
    # bag fixity attributes
    attribute :bag_validation_success, Valkyrie::Types::Int
    attribute :bag_validation_last_success_date, Valkyrie::Types::DateTime.optional
  end
end
