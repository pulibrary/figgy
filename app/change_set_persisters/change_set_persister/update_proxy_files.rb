# frozen_string_literal: true

class ChangeSetPersister
  class UpdateProxyFiles
    def self.proxies_membership?(resource)
      resource.respond_to?(:proxies_membership?) && resource.proxies_membership?
    end

    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    def run
      return unless self.class.proxies_membership?(resource) && !@change_set.member_ids.empty?

      # Only run this callback if the member IDs have been updated
      return unless @change_set.changed["member_ids"]

      update_member_proxies
    end

    private

      def resource
        @change_set.resource
      end

      def query_service
        @change_set_persister.metadata_adapter.query_service
      end

      def member_proxies
        query_service.find_many_by_ids(ids: @change_set.member_ids)
      end

      def update(proxy)
        cs = DynamicChangeSet.new(proxy)
        cs.prepopulate!
        @change_set_persister.save(change_set: cs)
      end

      def update_member_proxies
        member_proxies.map { |proxy| update(proxy) }
      end
  end
end
