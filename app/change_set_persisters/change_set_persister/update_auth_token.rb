# frozen_string_literal: true
class ChangeSetPersister
  class UpdateAuthToken
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      # Ensures that this model provides access using authorization tokens
      return unless change_set.resource.respond_to?(:auth_token) && change_set.resource.class.tokenized_access?

      remove_auth_token if current_auth_token.present? && change_set.state_changed? && change_set_incomplete_state?
      # Mints a new token only if this resource is in it's final state
      return unless change_set_final_state? && current_auth_token.blank?

      change_set.resource.auth_token = auth_token.token
      change_set
    end

    private

      def change_set_final_state?
        change_set.resource.decorate.public_readable_state?
      end

      def change_set_incomplete_state?
        !change_set_final_state?
      end

      def current_auth_token
        return @current_auth_token if @current_auth_token
        token = change_set.resource.auth_token
        @current_auth_token = AuthToken.find_by(token: token)
      end

      def remove_auth_token
        change_set.resource.auth_token = nil
      end

      def auth_token_label
        "Anonymous Token"
      end

      def auth_token_groups
        ["anonymous"]
      end

      def mint_auth_token
        AuthToken.create(label: auth_token_label, group: auth_token_groups, resource_id: change_set.resource.id.to_s)
      end

      def restored_auth_token
        AuthToken.find_by(resource_id: change_set.resource.id.to_s)
      end

      def auth_token
        restored_auth_token || mint_auth_token
      end
  end
end
