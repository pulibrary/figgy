# frozen_string_literal: true

module Migrations
  class InvalidResourceTypeError < StandardError; end

  class ResetBoxThumbnails
    def self.call(box_id:)
      new(box_id: box_id).run
    end

    attr_reader :box_id
    def initialize(box_id:)
      @box_id = box_id
      raise InvalidResourceTypeError unless box.is_a? EphemeraBox
    end

    # @return the number of thumbnails that were reset
    def run
      progress_bar
      reset = 0
      folders.each do |folder|
        progress_bar.progress += 1
        next if folder.thumbnail_id.blank?
        next if valid_thumbnail?(folder)

        new_thumbnail(folder)
        reset += 1
      end
      reset
    end

    private

      # true if the thumbnail was found and has a parent
      # false if the thumbnail is an orphan or wasn't found
      def valid_thumbnail?(folder)
        thumbnail_file_set = query_service.find_by(id: folder.thumbnail_id.first)
        thumbnail_parent = Wayfinder.for(thumbnail_file_set).parents
        thumbnail_parent.present?
      rescue Valkyrie::Persistence::ObjectNotFoundError
        # thumbnail id represented a deleted object
        false
      end

      def progress_bar
        @progress_bar ||= ProgressBar.create format: "%a %e %P% Folders Processed: %c of %C", total: folders.count
      end

      def new_thumbnail(folder)
        change_set = ChangeSet.for(folder)
        change_set.validate(thumbnail_id: folder.member_ids.first)
        ChangeSetPersister.default.save(change_set: change_set)
      end

      def folders
        @folders ||= Wayfinder.for(box).ephemera_folders
      end

      def box
        @box ||= query_service.find_by(id: box_id)
      end

      def query_service
        @query_service ||= Valkyrie.config.metadata_adapter.query_service
      end
  end
end
