# frozen_string_literal: true
# A base mixin for resources that hold files
module OptimisticLockProperty
  extend ActiveSupport::Concern

  included do
    # override this property to define a different default
    # optimistic locking is on in all Resources
    # this property still must be added to primary_fields in individual change sets
    property :optimistic_lock_token, multiple: true, require: false, type: Valkyrie::Types::Set.of(Valkyrie::Types::OptimisticLockToken)
  end
end
