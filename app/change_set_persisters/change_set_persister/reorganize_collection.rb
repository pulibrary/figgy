# frozen_string_literal: true

class ChangeSetPersister
  class ReorganizeCollection
    attr_reader :change_set_persister, :change_set, :post_save_resource
    delegate :metadata_adapter, to: :change_set_persister

    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless change_set.try(:reorganize) == true
      barcode_members
      barcode_lookup
      clean_old_relations
      IngestArchivalMediaBagJob::Ingester::DescriptiveProxyBuilder.new(
        barcode_lookup: barcode_lookup,
        component_groups: component_groups,
        changeset_persister: change_set_persister,
        collection: post_save_resource
      ).build!
    end

    def barcode_members
      @barcode_members ||=
        begin
          members = Wayfinder.for(post_save_resource).members.flat_map do |member|
            Wayfinder.for(member).members
          end
          members.select { |member| member.local_identifier.present? }
        end
    end

    def barcode_lookup
      @barcode_lookup ||= Hash[
        barcode_members.map do |member|
          [member.local_identifier.first, member.id]
        end
      ]
    end

    def clean_old_relations
      Wayfinder.for(post_save_resource).members.each do |resource|
        resource.member_ids = []
        change_set_persister.persister.save(resource: resource)
      end
    end

    def component_groups
      @component_groups ||=
        ArchivalMediaBagParser.new(path: nil, component_id: post_save_resource.source_metadata_identifier.first, barcodes: barcode_lookup.keys).component_groups
    end
  end
end
