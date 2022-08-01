# frozen_string_literal: true

class OcrRequest < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :pdf
end
