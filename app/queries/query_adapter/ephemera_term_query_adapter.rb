# frozen_string_literal: true
module QueryAdapter
  class EphemeraTermQueryAdapter < Base
    def find_by(label:, vocabulary: nil)
      vocab_label = vocabulary.try(:label)
      term = FindEphemeraTermByLabel.new(query_service: @query_service).find_term_by_label(label: label, vocab_label: vocab_label)
      term.decorate if term.present?
    end

    def all
      @query_service.find_all_of_model(model: EphemeraTerm).map(&:decorate)
    end
  end
end
