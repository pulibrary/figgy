# frozen_string_literal: true
class QueryAdapter
  class EphemeraVocabularyQueryAdapter < QueryAdapter
    def find_by(label:, vocabulary: nil)
      category_label = vocabulary.try(:label)
      vocabulary = FindEphemeraVocabularyByLabel.new(query_service: @query_service).find_vocabulary_by_label(label: label, category_label: category_label)
      vocabulary.decorate if vocabulary.present?
    end

    def all
      @query_service.find_all_of_model(model: EphemeraVocabulary).map(&:decorate)
    end
  end
end
