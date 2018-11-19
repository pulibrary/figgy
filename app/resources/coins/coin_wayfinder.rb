# frozen_string_literal: true
class CoinWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :numismatic_citations, property: :numismatic_citation_ids, singular: false
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  def members_with_parents
    @members_with_parents ||= members.map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end

  def accession
    @accession ||= accessions.first&.decorate
  end

  private

    def accessions
      query_service.custom_queries
                   .find_by_numeric_property(property: :accession_number, value: accession_number)
                   .select { |o| o.is_a?(NumismaticAccession) }
    end

    def accession_number
      Array.wrap(resource.accession_number).first
    end
end
