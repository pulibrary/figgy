# frozen_string_literal: true
class ChangeSetPersister
  # This either mints a new auth. token for a resource which has just been completed...
  # ...or revokes it for a Resource which has been updated as incomplete
  class UpdateAuthToken
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      # Ensures that this model provides access using authorization tokens
      return unless change_set.resource.respond_to?(:auth_token) && change_set.resource.class.tokenized_access?

      return if change_set.resource.auth_token.nil?
      update
    end

    private

      def update
        token = AuthToken.find_by(token: change_set.resource.auth_token)
        return if token.resource_id?

        token.update(resource_id: @post_save_resource.id.to_s)
      end
  end
end
