# frozen_string_literal: true

class RightsStatements
  class << self
    def copyright_not_evaluated
      find_by_label("Copyright Not Evaluated")
    end

    def in_copyright
      find_by_label("In Copyright")
    end

    def in_copyright_unknown_holders
      find_by_label("In Copyright - Rights-holder(s) Unlocatable or Unidentifiable")
    end

    def in_copyright_educational_use
      find_by_label("In Copyright - Educational Use Permitted")
    end

    def in_copyright_noncommercial_use
      find_by_label("In Copyright - NonCommercial Use Permitted")
    end

    def no_copyright_contractual_restrictions
      find_by_label("No Copyright - Contractual Restrictions")
    end

    def no_copyright_other_restrictions
      find_by_label("No Copyright - Other Known Legal Restrictions")
    end

    def no_known_copyright
      find_by_label("No Known Copyright")
    end

    def vatican_copyright
      find_by_label("This title is reproduced by permission of the Vatican Library")
    end

    def vocabulary
      ControlledVocabulary.for(:rights_statement)
    end

    def find_by_label(label)
      RDF::URI(
        vocabulary.all.find do |term|
          term.label == label
        end.value
      )
    end
  end
end
