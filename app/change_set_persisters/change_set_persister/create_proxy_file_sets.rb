# frozen_string_literal: true
class ChangeSetPersister
  class CreateProxyFileSets
    attr_reader :change_set_persister, :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless file_set_ids.present?
      change_set.member_ids += proxy_file_set_ids
      change_set.sync
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
