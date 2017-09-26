# frozen_string_literal: true
class PlumChangeSetPersister
  class PublishMessage
    class Factory
      attr_reader :operation
      def initialize(operation:)
        @operation = operation
      end

      def new(*args)
        klass.new(*args)
      end

      private

        def klass_name
          "PlumChangeSetPersister::Publish#{operation.to_s.capitalize}#{'e' unless operation.to_s.last == 'e'}dMessage"
        end

        def klass
          klass_name.constantize
        rescue
          raise NotImplementedError, "#{klass_name} not supported as a change set persistence handler"
        end
    end
  end

  class PublishCreatedMessage
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      created_file_sets.each { |created_file_set| messenger.record_created(created_file_set) } unless created_file_sets.blank?
    end

    delegate :messenger, :created_file_sets, to: :change_set_persister
  end

  class PublishUpdatedMessage
    attr_reader :change_set_persister, :change_set, :post_save_resource
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      messenger.record_updated(post_save_resource)
    end

    delegate :messenger, to: :change_set_persister
  end

  class PublishDeletedMessage
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      messenger.record_deleted(change_set.resource)
    end

    delegate :messenger, to: :change_set_persister
  end
end
