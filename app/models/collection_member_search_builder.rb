# frozen_string_literal: true
class CollectionMemberSearchBuilder < ::SearchBuilder
  class_attribute :collection_membership_field
  self.collection_membership_field = "member_of_collection_ids_ssim"
  self.default_processor_chain += [:member_of_collection]

  def member_of_collection(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << "#{collection_membership_field}:id-#{collection_id}"
  end

  private

    def collection_id
      @scope.resource.id || raise("Collection does not have an identifier")
    end
end
