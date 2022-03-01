# frozen_string_literal: true
class VocabularyValidator < ActiveModel::Validator
  def validate(record)
    validate_vocabulary record
  end

  private

    def find_resource(id:)
      Valkyrie.config.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(id))
    end

    def valid_uuid?(value)
      /^[A-F\d]{8}-[A-F\d]{4}-4[A-F\d]{3}-[89AB][A-F\d]{3}-[A-F\d]{12}$/i.match? value
    end

    def resource_exists?(uuid:, record:)
      unless valid_uuid? uuid.to_s
        record.errors.add(:member_of_vocabulary_id, "#{uuid} is not a valid UUID")
        return false
      end
      resource = find_resource(id: uuid)
      resource.present?
    rescue Valkyrie::Persistence::ObjectNotFoundError
      record.errors.add(:member_of_vocabulary_id, "#{uuid} does not resolve to a resource")
      false
    end

    def validate_vocabulary(record)
      vocabulary_ids = Array.wrap(record.member_of_vocabulary_id)
      return true if vocabulary_ids.first.blank?
      vocabulary_ids.map { |vocabulary_id| resource_exists?(uuid: vocabulary_id, record: record) }.reduce(:|)
    end
end
