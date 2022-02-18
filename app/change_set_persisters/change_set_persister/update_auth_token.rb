# frozen_string_literal: true

class ChangeSetPersister
  # Updates any AuthTokens by storing the ID for the related Resource
  class UpdateAuthToken
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      # Ensures that this model provides access using authorization tokens
      return unless tokenized_access?

      return if change_set.resource.auth_token.nil?
      update
    end

    private

      def tokenized_access?
        change_set.resource.class.respond_to?(:tokenized_access?) && change_set.resource.class.tokenized_access?
      end

      def update
        token = AuthToken.find_by(token: change_set.resource.auth_token)
        return if token.resource_id?

        token.update(resource_id: @post_save_resource.id.to_s)
      end
  end
end
