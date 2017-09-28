# frozen_string_literal: true
module BrowseEverythingable
  extend ActiveSupport::Concern

  included do
    def browse_everything_files
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        change_set.validate(pending_uploads: change_set.pending_uploads + selected_files)
        change_set.sync
        buffered_changeset_persister.save(change_set: change_set)
      end
      BrowseEverythingIngestJob.perform_later(resource.id.to_s, self.class.to_s, selected_files.map(&:id).map(&:to_s))
      redirect_to Valhalla::ContextualPath.new(child: resource, parent_id: nil).file_manager
    end

    def selected_file_params
      params[:selected_files].to_unsafe_h
    end

    def selected_files
      @selected_files ||= selected_file_params.values.map do |x|
        PendingUpload.new(x.symbolize_keys.merge(id: SecureRandom.uuid, created_at: Time.current.utc.iso8601))
      end
    end
  end
end
