# frozen_string_literal: true
class ChangeSetPersister
  class CreateFile
    class Factory
      attr_reader :file_appender
      def initialize(file_appender: FileAppender)
        @file_appender = file_appender
      end

      def new(**args)
        CreateFile.new(args.merge(file_appender: file_appender))
      end
    end
    attr_reader :change_set_persister, :change_set, :file_appender
    delegate :persister, :storage_adapter, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil, file_appender:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @file_appender = file_appender
    end

    def run
      return unless change_set.respond_to?(:created_file_sets=)
      appender = file_appender.new(files: files, parent: change_set.resource, change_set_persister: change_set_persister)
      created_file_sets = appender.append
      change_set.created_file_sets += created_file_sets
    end

    def files
      change_set.try(:files) || []
    end
  end
end
