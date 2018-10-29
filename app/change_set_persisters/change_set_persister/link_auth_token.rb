# frozen_string_literal: true
class ChangeSetPersister
  class LinkAuthToken
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      # Ensures that this model provides access using authorization tokens
      return unless change_set.resource.respond_to?(:auth_token) && change_set.resource.class.tokenized_access?

      return if change_set.resource.auth_token.blank?
      auth_token = AuthToken.find_by(token: change_set.resource.auth_token)
      return unless auth_token.resource_id.blank?
      auth_token.update(resource_id: @post_save_resource.id)
    end
  end
end
