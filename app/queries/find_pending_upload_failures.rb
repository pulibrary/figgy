# frozen_string_literal: true
class FindPendingUploadFailures
  def self.queries
    [:find_pending_upload_failures]
  end

  attr_reader :query_service
  delegate :resources, to: :query_service
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_pending_upload_failures
    relation = { "pending_uploads" => [], "state" => ["pending"] }
    metadata = Sequel.pg_jsonb_op(:metadata)
    # rubocop:disable Style/PreferredHashMethods
    resources.use_cursor.where(
      metadata.has_key?("pending_uploads") && metadata.has_key?("state")
    ).where(
      metadata.contains(relation)
    ).use_cursor.lazy.map do |attributes|
      resource_factory.to_resource(object: attributes)
    end
    # rubocop:enable Style/PreferredHashMethods
  end
end
