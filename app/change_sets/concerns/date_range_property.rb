# frozen_string_literal: true

# A mixin adding supporting code for the DateRange nested resource
# Once this mixin is included you need to add date_range_form to the list of
#   primary_terms on the change set
module DateRangeProperty
  extend ActiveSupport::Concern

  included do
    property :date_range, multiple: false, required: false
    property :date_range_form_attributes, virtual: true

    def date_range_form_attributes=(attributes)
      return unless date_range_form.validate(attributes)
      date_range_form.sync
      self.date_range = date_range_form.model
    end

    def date_range_form
      @date_range_form ||= ChangeSet.for(date_range_value || DateRange.new).tap(&:prepopulate!)
    end

    def date_range_value
      Array.wrap(date_range).first
    end

    validate :date_range_validity

    def date_range_validity
      return if date_range_form.valid?
      errors.add(:date_range_form, "is not valid.")
    end
  end
end
