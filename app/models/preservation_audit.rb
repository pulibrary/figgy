# frozen_string_literal: true
class PreservationAudit < ApplicationRecord
  has_many :preservation_check_failures, dependent: :destroy
  belongs_to :ids_from, class_name: "PreservationAudit", optional: true

  validates :batch_id, presence: true
  validates :status, inclusion: {
    in: %w[in_process success failure complete dead], message: "%{value} is not a valid status"
  }
  validates :extent, inclusion: {
    in: %w[full partial], message: "%{value} is not a valid extent"
  }
end
