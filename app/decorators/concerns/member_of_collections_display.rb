# frozen_string_literal: true
module MemberOfCollectionsDisplay
  extend ActiveSupport::Concern
  included do
    self.display_attributes += [:member_of_collections]

    def member_of_collections
      @member_of_collections ||=
        begin
          query_service.find_references_by(resource: model, property: :member_of_collection_ids)
                       .map(&:decorate)
                       .map(&:title).to_a
        end
    end
  end
end
