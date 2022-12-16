# frozen_string_literal: true
class ChangeSetPersister
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
          "ChangeSetPersister::Publish#{operation.to_s.camelize}#{'e' unless operation.to_s.last == 'e'}dMessage"
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
    delegate :created_file_sets, to: :change_set
    def initialize(change_set_persister:, change_set: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.respond_to?(:created_file_sets)
      created_file_sets.each { |created_file_set| messenger.record_created(created_file_set) } if created_file_sets.present?
    end

    delegate :messenger, to: :change_set_persister
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
      # For cases where the resource is a FileSet, propagate for the parent resource
      return unless post_save_resource.is_a? FileSet
      parent = Wayfinder.for(post_save_resource).parent
      messenger.record_member_updated(parent)
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

  class PublishDerivativesDeletedMessage
    attr_reader :change_set_persister, :change_set
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      messenger.derivatives_deleted(change_set.resource) if change_set.resource.is_a? FileSet
    end

    delegate :messenger, to: :change_set_persister
  end
end
