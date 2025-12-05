class PreservationAudit < ApplicationRecord
  validates :batch_id, presence: true
  validates :status, inclusion: {
    in: %w[in_process success failure], message: "%{value} is not a valid status"
  }
  validates :extent, inclusion: {
    in: %w[full partial], message: "%{value} is not a valid extent"
  }
end
