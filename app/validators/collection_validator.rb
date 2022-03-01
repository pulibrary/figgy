# frozen_string_literal: true
class CollectionValidator < ActiveModel::Validator
  def validate(record)
    validate_collection record
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
        record.errors.add(:member_of_collection_ids, "#{uuid} is not a valid UUID")
        return false
      end
      resource = find_resource(id: uuid)
      resource.present?
    rescue Valkyrie::Persistence::ObjectNotFoundError
      record.errors.add(:member_of_collection_ids, "#{uuid} does not resolve to a resource")
      false
    end

    def validate_collection(record)
      return true if Array.wrap(record.member_of_collection_ids).first.blank?
      record.member_of_collection_ids.map { |collection_id| resource_exists?(uuid: collection_id, record: record) }.reduce(:|)
    end
end
