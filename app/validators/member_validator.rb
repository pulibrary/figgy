# frozen_string_literal: true
class MemberValidator < ActiveModel::Validator
  def validate(record)
    validate_member record
  end

  private

    def valid_uuid?(value)
      /^[A-F\d]{8}-[A-F\d]{4}-4[A-F\d]{3}-[89AB][A-F\d]{3}-[A-F\d]{12}$/i.match? value
    end

    def nonexistent_ids(ids)
      ids - query_service.custom_queries.find_saved_ids(ids: ids)
    end

    def query_service
      Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    end

    def validate_member(record)
      return true if Array.wrap(record.member_ids).first.blank?
      return true unless record.changed?(:member_ids)
      valid_ids = record.member_ids.select { |id| valid_uuid?(id.to_s) }
      (record.member_ids - valid_ids).each do |member_id|
        record.errors.add(:member_ids, "#{member_id} is not a valid UUID")
      end
      # Check for any new member IDs that are pointed at nonexistent resources.
      # Don't check old ones, there may be stale data in there and we don't want
      # to prevent it saving for our users over that.
      new_ids = valid_ids - record.resource.member_ids
      nonexistent_ids(new_ids).each do |id|
        record.errors.add(:member_ids, "#{id} does not resolve to a resource")
      end
    end
end
