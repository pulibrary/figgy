# frozen_string_literal: true

class AutoIncrementValidator < ActiveModel::Validator
  def validate(record)
    return if record.send(property).to_i.positive?
    highest = highest_value || 0
    record.send("#{property}=", highest + 1)
  end

  private

    def property
      options[:property]
    end

    def highest_value
      query_service.custom_queries.find_highest_value(property: property)&.to_i
    end

    def query_service
      Valkyrie.config.metadata_adapter.query_service
    end
end
