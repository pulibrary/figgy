# frozen_string_literal: true

class ChangeSetPersister
  class DeleteAuthToken
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless tokenized_access?
      return unless auth_token

      auth_token.destroy
    end

    private

      def tokenized_access?
        change_set.resource.class.respond_to?(:tokenized_access?) && change_set.resource.class.tokenized_access?
      end

      # Retrieves the auth token for a given Resource
      # @return [AuthToken]
      def auth_token
        AuthToken.find_by(resource_id: change_set.resource.id.to_s)
      end
  end
end
