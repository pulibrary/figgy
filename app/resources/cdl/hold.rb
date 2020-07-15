# frozen_string_literal: true

module CDL
  class Hold < Valkyrie::Resource
    attribute :netid, Valkyrie::Types::String
    attribute :expiration_time, Valkyrie::Types::Time.optional
    attribute :notification_time, Valkyrie::Types::Time.optional

    def active?
      expiration_time.present?
    end

    def expired?
      expiration_time <= Time.current
    end
  end
end
