# frozen_string_literal: true

class ParentValidator < ActiveModel::Validator
  def validate(record)
    validate_parent record
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
        record.errors.add(:parent_id, "#{uuid} is not a valid UUID")
        return false
      end
      resource = find_resource(id: uuid)
      resource.present?
    rescue Valkyrie::Persistence::ObjectNotFoundError
      record.errors.add(:parent_id, "#{uuid} does not resolve to a resource")
      false
    end

    def validate_parent(record)
      parent_ids = Array.wrap(record.parent_id)
      return true unless parent_ids.first.present?
      parent_ids.map { |parent_id| resource_exists?(uuid: parent_id, record: record) }.reduce(:|)
    end
end
