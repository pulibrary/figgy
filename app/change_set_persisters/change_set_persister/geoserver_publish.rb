# frozen_string_literal: true
class ChangeSetPersister
  class GeoserverPublish
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
          "ChangeSetPersister::GeoserverPublish#{operation.to_s.camelize}"
        end

        def klass
          klass_name.constantize
        rescue
          raise NotImplementedError, "#{klass_name} not supported as a change set persistence handler"
        end
    end
  end

  class GeoserverPublishUpdate
    attr_reader :change_set_persister, :change_set, :post_save_resource
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @post_save_resource = post_save_resource
    end

    def run
      return unless valid?
      if takedown?
        GeoserverPublishJob.perform_later(operation: "delete", resource_id: post_save_resource.id.to_s)
      elsif updated_properties? || complete?
        GeoserverPublishJob.perform_later(operation: "update", resource_id: post_save_resource.id.to_s)
      end
    end

    private

      def updated_properties?
        change_set.changed?(:title) || change_set.changed?(:visibility)
      end

      def complete?
        change_set.changed?(:state) && change_set.state.to_s == "complete"
      end

      def takedown?
        change_set.changed?(:state) && change_set.state.to_s == "takedown"
      end

      def valid?
        return false unless post_save_resource.is_a?(VectorResource)
        post_save_resource.decorate.geo_members.present?
      end
  end

  class GeoserverPublishDelete
    attr_reader :change_set_persister, :change_set, :resource
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @resource = change_set.resource
    end

    def run
      return unless valid?
      GeoserverPublishJob.perform_now(operation: "delete", resource_id: resource.id.to_s)
    end

    private

      def valid?
        return false unless resource.is_a?(VectorResource)
        resource.decorate.geo_members.present?
      end
  end

  class GeoserverPublishDerivativesDelete
    attr_reader :change_set_persister, :change_set, :resource
    def initialize(change_set_persister:, change_set:)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @resource = change_set.resource
    end

    def run
      return unless valid?
      GeoserverPublishJob.perform_now(operation: "derivatives_delete", resource_id: resource.id.to_s)
    end

    private

      def valid?
        return false unless resource.is_a? FileSet
        resource.decorate.parent.is_a?(VectorResource)
      end
  end
end
