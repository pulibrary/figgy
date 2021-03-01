# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class BasicMetadataBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      # Builds fields such as id, subject, and publisher.
      # @param [AbstractDocument] discovery document
      def build(document)
        build_simple_attributes(document)
        build_complex_attributes(document)
      end

      private

        # Builds more complex metadata attributes.
        # @param [AbstractDocument] discovery document
        def build_complex_attributes(document)
          document.access_rights = resource_decorator.model.visibility.first
          document.call_number = call_number
          document.description = description
          document.identifier = identifier
          document.title = title
          document.subject = subject
          document.all_subject = unfiltered_subject
        end

        # Builds simple metadata attributes.
        # @param [AbstractDocument] discovery document
        def build_simple_attributes(document)
          simple_attributes.each do |a|
            value = resource_decorator.send(a.to_s)
            next if value.nil? || value.empty?
            document.send("#{a}=", value)
          end
        end

        def call_number
          return unless resource_decorator.call_number
          call_numbers = resource_decorator.call_number.reject { |c| c == "Electronic Resource" }
          call_numbers.try(:first)
        end

        # Returns the work description. If none is available,
        # a basic description is created.
        # @return [String] description
        def description
          return resource_decorator.description.join(" ") unless resource_decorator.description.empty?
          "A #{resource_decorator.human_readable_type.downcase} object."
        end

        # Returns the work indentifier. This is (usually) different from the hydra/fedora work id.
        # The identifier might be an ARK, DOI, PURL, etc.
        # If identifier is not set, the work id is used.
        # @return [String] identifier
        def identifier
          identifiers = resource_decorator.identifier
          return identifiers.first unless identifiers.nil? || identifiers.empty?
          resource_decorator.id.to_s
        end

        # Returns an array of attributes to add to document.
        # @return [Array<Symbol>] attributes
        def simple_attributes
          [:creator, :spatial, :temporal,
           :held_by, :language, :publisher]
        end

        # Returns an array of subject strings. For Vector and Raster Resources,
        # non ISO 19115 topic category subjects are filtered out.
        # @return [Array<String>] subjects
        def subject
          return resource_decorator.subject if resource_decorator.model.is_a?(ScannedMap)
          resource_decorator.subject.select { |v| topic_categories.value?(v) }
        end

        # Use the standard resource decorator to retreive title.
        # @return [String] title
        def title
          # This convoluted set ot method calls is required because, in this case, we need the
          # actual model decorator rather than the geoblacklight metadata decorator.
          decorated_title = resource_decorator.model.decorate.title.try(:first)
          decorated_title&.to_s
        end

        def topic_categories
          GeoMetadataExtractor::Fgdc::TOPIC_CATEGORIES
        end

        # Returns an array of unfiltered subject strings.
        # @return [Array<String>] subjects
        def unfiltered_subject
          resource_decorator.subject
        end
    end
  end
end
