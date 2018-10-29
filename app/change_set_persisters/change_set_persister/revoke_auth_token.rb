# frozen_string_literal: true
class ChangeSetPersister
  class RevokeAuthToken
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, :transaction?, to: :change_set_persister
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.resource.respond_to?(:auth_token) && change_set.resource.class.tokenized_access?
      return unless auth_token

      auth_token.destroy
    end

    private

      def auth_token
        token = change_set.resource.auth_token
        AuthToken.find_by(token: token)
      end
  end
end
