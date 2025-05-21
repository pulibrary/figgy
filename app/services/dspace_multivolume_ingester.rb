# frozen_string_literal: true

class DspaceMultivolumeIngester < DspaceCollectionIngester
  def ark_url
    "http://arks.princeton.edu/ark:/#{ark}"
  end

  def find_or_persist_parent_resource(**resource_attrs)
    default_attrs = {
      title: [title],
      identifier: [ark_url],
      source_metadata_identifier: nil
    }

    attrs = default_attrs.merge(resource_attrs)

    find_or_persist_resource(**attrs)
  end

  def ingest!(**attrs)
    logger.info("Ingesting DSpace collection #{id} as a multi-volume Work...")

    ingest_items(**attrs)
  end

  private

    def ingest_items(**attrs)
      parent_attrs = {}
      parent_attrs[:member_of_collection_ids] = attrs[:member_of_collection_ids]
      parent_resource = find_or_persist_parent_resource(**parent_attrs)

      attrs[:parent_id] = parent_resource.id.to_s

      super(**attrs)
    end

    def persist_resource(**attrs)
      raise("Invalid attributes: #{resource_change_set.errors.full_messages.to_sentence}") unless resource_change_set.validate(**attrs)

      new_parent = change_set_persister.save(change_set: resource_change_set)

      new_parent
    end

    def find_or_persist_resource(**attrs)
      results = find_resources_by_ark(value: ark_url)
      persisted = nil
      if @delete_preexisting
        results.each do |resource|
          change_set_persister.metadata_adapter.persister.delete(resource: resource)
        end
      else
        persisted = results.last
      end

      return persisted unless persisted.nil?

      persist_resource(**attrs)
    end
end
