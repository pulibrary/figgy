# frozen_string_literal: true
class ChangeSetPersister
  class CreateProxyFileSets
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :metadata_adapter, to: :change_set_persister
    delegate :persister, to: :metadata_adapter

    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return if file_set_ids.blank?
      change_set.member_ids += proxy_file_set_ids
      change_set.sync
    end

    def proxy_file_set_ids
      proxy_file_sets.map(&:id)
    end

    def proxy_file_sets
      @proxy_file_sets ||=
        file_sets.map do |file_set|
          persister.save(resource: ProxyFileSet.new(proxied_file_id: file_set.id, label: file_set.title))
        end
    end

    def file_set_ids
      @file_set_ids ||= (change_set.try(:file_set_ids) || []) - current_member_ids
    end

    def current_member_ids
      return [] if change_set.try(:file_set_ids).blank?
      @current_members ||= Wayfinder.for(change_set.resource).members.map(&:proxied_file_id)
    end

    def file_sets
      @file_sets ||= query_service.find_many_by_ids(ids: file_set_ids).sort_by { |x| file_set_ids.index(x.id) }
    end
  end
end
