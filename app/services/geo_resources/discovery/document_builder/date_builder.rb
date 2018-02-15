# frozen_string_literal: true
module GeoResources
  module Discovery
    class DocumentBuilder
      class DateBuilder
        attr_reader :resource_decorator

        def initialize(resource_decorator)
          @resource_decorator = resource_decorator
        end

        # Builds date fields such as layer year and modified date.
        # @param [AbstractDocument] discovery document
        def build(document)
          document.layer_year = layer_year
          document.layer_modified = layer_modified
          document.issued = issued
        end

        private

          # Returns the date the layer was issued.
          # @return [String] date in XMLSchema format.
          def issued
            datetime = resource_decorator.issued.first
            datetime = DateTime.parse(datetime).utc
            datetime.utc.xmlschema
          rescue
            ''
          end

          # Returns the date the work was modified.
          # @return [String] date in XMLSchema format.
          def layer_modified
            resource_decorator.model.updated_at.utc.xmlschema
          end

          # Returns a year associated with the layer. Taken from first
          # value in temporal or from resource created date.
          # @return [Integer] year
          def layer_year
            date = resource_decorator.temporal.first || resource_decorator.model.created_at
            year = date.match(/(?<=\D|^)(\d{4})(?=\D|$)/)
            year ? year[0].to_i : nil
          rescue
            ''
          end
      end
    end
  end
end
