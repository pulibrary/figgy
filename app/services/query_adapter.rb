# frozen_string_literal: true
class QueryAdapter
  def initialize(query_service:, model:)
    @query_service = query_service
    @model = model
  end

  def find_with(query_class, *args)
    Array.wrap(query_class.new(query_service: @query_service).send(query_method(query_class), *args)).map(&:decorate)
  end

  def all
    @query_service.find_all_of_model(model: @model).to_a.map(&:decorate)
  end

  private

    def query_method(query_class)
      query_class.to_s.underscore
    end
end
