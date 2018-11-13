# frozen_string_literal: true
class ChangeSetPersister
  class CreateProxyFileSets
    attr_reader :change_set_persister, :change_set
    delegate :query_service, to: :change_set_persister
    delegate :resource, to: :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      if detached_proxy_file_set_ids.present?
        delete_detached_proxy_file_sets
        change_set.member_ids = attached_proxy_file_set_ids
      else
        return if file_set_ids.nil?
        change_set.member_ids += proxy_file_set_ids
      end

      change_set.sync
    end

    def detached_proxy_file_set_ids
      change_set.try(:detached_member_ids)
    end

    def detached_proxy_file_sets
      @detached_proxy_file_sets ||= query_service.find_many_by_ids(ids: detached_proxy_file_set_ids)
    end

    def attached_proxy_file_set_ids
      resource.member_ids - detached_proxy_file_set_ids
    end

    def delete_detached_proxy_file_sets
      detached_proxy_file_sets.each do |proxy_file_set|
        cs = ProxyFileSetChangeSet.new(proxy_file_set)
        cs.prepopulate!
        change_set_persister.delete(change_set: cs)
      end
    end

    def proxy_file_set_ids
      proxy_file_sets.map(&:id)
    end

    def proxy_file_sets
      @proxy_file_sets ||=
        begin
          file_sets.map do |file_set|
            persister.save(resource: ProxyFileSet.new(proxied_file_id: file_set.id, label: file_set.title))
          end
        end
    end

    def file_set_ids
      change_set.try(:file_set_ids)
    end

    def file_sets
      @file_sets ||= query_service.find_many_by_ids(ids: file_set_ids)
    end

    def query_service
      change_set_persister.metadata_adapter.query_service
    end

    def persister
      change_set_persister.metadata_adapter.persister
    end
  end
end
