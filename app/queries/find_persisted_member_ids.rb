class FindPersistedMemberIds
  def self.queries
    [:find_member_ids]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  # Return all member ids as a result of joind query.
  # This is useful when member_ids contains ids of deleted resources.
  def find_persisted_member_ids(resource:)

  end
end
