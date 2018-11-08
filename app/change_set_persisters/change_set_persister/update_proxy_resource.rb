# frozen_string_literal: true

class ChangeSetPersister
  class UpdateProxyResource
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    def run
      # Only update the proxied resources if they've been newly added
      return unless resource.respond_to?(:proxied_file_id) && @change_set.changed["proxied_file_id"]

      update
    end

    private

      def resource
        @change_set.resource
      end

      def query_service
        @change_set_persister.metadata_adapter.query_service
      end

      def proxied_resource
        query_service.find_by(id: @change_set.proxied_file_id)
      end

      def update
        # Add more proxy attributes here
        attributes = {
          label: proxied_resource.title
        }
        @change_set.validate(attributes)
        @change_set.sync
        @change_set
      end
  end
end
