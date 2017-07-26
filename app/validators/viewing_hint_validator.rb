# frozen_string_literal: true
class ViewingHintValidator < ActiveModel::Validator
  delegate :validate, to: :inclusivity_validator

  private

    def inclusivity_validator
      @inclusivity_validator ||= ActiveModel::Validations::InclusionValidator.new(
        attributes: :viewing_hint,
        in: valid_viewing_hints,
        allow_blank: true
      )
    end

    def valid_viewing_hints
      [
        "continuous",
        "paged",
        "individuals",
        "non-paged",
        "facing-pages"
      ].map { |x| Array.wrap(x) }
    end
end
