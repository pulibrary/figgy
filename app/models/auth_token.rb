class AuthToken < ApplicationRecord
  before_create :assign_token
  before_save :clean_group
  serialize :group, coder: YAML, type: Array
  validates :label, presence: true

  private

    def assign_token
      self.token = SecureRandom.hex
    end

    def clean_group
      self.group = group.select(&:present?)
    end
end
