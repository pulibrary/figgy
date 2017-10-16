# frozen_string_literal: true
class EphemeraProjectDecorator < Valkyrie::ResourceDecorator
  self.display_attributes = [:title]

  def members
    @members ||= query_service.find_members(resource: model).to_a
  end

  def boxes
    @boxes ||= members.select { |r| r.is_a?(EphemeraBox) }.map(&:decorate).to_a
  end

  def fields
    @fields ||= members.select { |r| r.is_a?(EphemeraField) }.map(&:decorate).to_a
  end

  def templates
    @templates ||= query_service.find_inverse_references_by(resource: self, property: :parent_id).map(&:decorate).to_a
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  def title
    super.first
  end

  # Access (or generate) the slug ID for the decorated resource
  # @return [String] the slug value
  def slug
    value = super
    generated_slug.value unless value.present?
  end

  def iiif_manifest_attributes
    local_attributes(self.class.iiif_manifest_attributes).merge iiif_manifest_exhibit
  end

  # A local identifier (slug) generated for EphemeraProjects
  class Slug
    attr_reader :value

    # Initialize using a prefix, seed, and optional delimiter
    # @param prefix [String] the prefix for the slug ID
    # @param seed [String] the value used to generate the suffix for the slug
    # @param delimiter [String] the delimiter used between the prefix and suffix
    def initialize(prefix:, seed:, delimiter: '-')
      @prefix = prefix
      @seed = seed
      @delimiter = delimiter
      @value = generate
    end
    alias to_s value

    private

      # Generate the slug ID value
      # @return [String] the string value used as the slug
      def generate
        @prefix + @delimiter + @seed.slice(0, 4)
      end
  end

  private

    # Generate the slug prefix from the existing label
    # @return [String] the prefix for the slug
    def generated_slug_prefix
      title.gsub(/\s/, '_').downcase
    end

    # Generate the slug value from the Valkyrie Resource ID
    # @return [Slug] the slug for the resource
    def generated_slug
      @slug ||= Slug.new(prefix: generated_slug_prefix, seed: model.id.to_s)
    end

    # Generate the Hash for the IIIF Manifest metadata exposing the slug as an "Exhibit" property
    # @return [Hash] the exhibit metadata hash
    def iiif_manifest_exhibit
      { exhibit: slug }
    end
end
