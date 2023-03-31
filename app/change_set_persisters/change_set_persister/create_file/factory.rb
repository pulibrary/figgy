# frozen_string_literal: true
class ChangeSetPersister
  class CreateFile
    class Factory
      attr_reader :file_appender
      def initialize(file_appender: FileAppender)
        @file_appender = file_appender
      end

      def new(**args)
        CreateFile.new(**args.merge(file_appender: file_appender))
      end
    end
  end
end
