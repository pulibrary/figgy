# frozen_string_literal: true

class ChangeSetPersister
  # Mints a new AuthToken for Resources which support token-authorized access which have the mint_auth_token ChangeSet flag, or which have reached the final state in their workflow
  class ApplyAuthToken
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      # Ensures that this model provides access using authorization tokens
      return unless tokenized_access?

      # Mints a new token only if this resource is in it's final state
      return unless change_set_mint_auth_token? || (change_set_final_state? && current_auth_token.blank?)

      change_set.validate(auth_token: auth_token.token)
      change_set.sync
    end

    private

      def change_set_mint_auth_token?
        change_set.changed["mint_auth_token"] && change_set["mint_auth_token"].first
      end

      def tokenized_access?
        change_set.resource.class.respond_to?(:tokenized_access?) && change_set.resource.class.tokenized_access?
      end

      def change_set_final_state?
        change_set.resource.decorate.public_readable_state?
      end

      def current_auth_token
        return @current_auth_token if @current_auth_token
        token = change_set.resource.auth_token
        @current_auth_token = AuthToken.find_by(token: token)
      end

      def auth_token_label
        "Anonymous Token"
      end

      def auth_token_groups
        ["anonymous"]
      end

      def auth_token
        current_auth_token&.destroy
        AuthToken.create(label: auth_token_label, group: auth_token_groups)
      end
  end
end
