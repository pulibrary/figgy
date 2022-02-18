# frozen_string_literal: true

class RightsStatementValidator < ActiveModel::Validator
  # ensure the property exists and is in the controlled vocabulary
  def validate(record)
    return if ControlledVocabulary.for(:rights_statement).find(record.rights_statement)
    record.errors.add :rights_statement, "#{record.rights_statement} is not a valid rights_statement"
  end
end
