# frozen_string_literal: true
class PreservationCheckFailure < ApplicationRecord
  belongs_to :preservation_audit
end
