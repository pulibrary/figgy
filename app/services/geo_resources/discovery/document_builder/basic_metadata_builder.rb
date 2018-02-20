# frozen_string_literal: true
module GeoResources
  module Discovery
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
            document.description = description
            document.identifier = identifier
            document.title = title
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
          # @return [Array] attributes
          def simple_attributes
            [:creator, :subject, :spatial, :temporal,
             :provenance, :language, :publisher]
          end

          def title
            titles = resource_decorator.title
            titles&.first.to_s
          end
      end
    end
  end
end
