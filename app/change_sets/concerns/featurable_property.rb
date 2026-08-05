# Mixin to add a property that indicates whether a resource can be featured in a
# Digital Collections collection or project.
module FeaturableProperty
  extend ActiveSupport::Concern

  included do
    property :featurable, multiple: true, required: false, default: [], type: Types::Strict::Array.of(Valkyrie::Types::ID)

    # Ensures that previous featurable values are not returned so the edit page
    # works as expected. Can be removed once all the resources have been migrated.
    def featurable
      Array.wrap(super).reject { |value| ["0", "1"].include?(value.to_s) }
    end

    def featurable_options
      (featurable_collections + featurable_ephemera_projects).map do |target|
        { "id" => target.id.to_s, "label" => Array.wrap(target.title).first.to_s }
      end
    end

    def featurable_collections
      collections = Valkyrie.config.metadata_adapter.query_service.find_many_by_ids(ids: Array.wrap(member_of_collection_ids))
      collections.sort_by { |collection| Array.wrap(collection.title).first.to_s }
    end

    def featurable_ephemera_projects
      return [] unless resource.persisted?
      Array.wrap(Wayfinder.for(resource).try(:ephemera_projects)).compact
    end
  end
end
