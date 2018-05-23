# frozen_string_literal: true
class SimpleResourceDecorator < Valkyrie::ResourceDecorator
  display Schema::Common.attributes, :member_of_collections
  display :visibility, # No RDF URI - See hydra-access-controls
          :abstract, # http://purl.org/dc/terms/abstract
          :alternative, # http://purl.org/dc/terms/alternative
          :alternative_title, # http://purl.org/dc/terms/alternative
          :bibliographic_citation, # http://purl.org/dc/terms/bibliographicCitation
          :contents, # http://purl.org/dc/terms/tableOfContents
          :created, # http://purl.org/dc/terms/created
          :date_created, # http://purl.org/dc/terms/created
          :extent, # http://purl.org/dc/terms/extent
          :genre, # http://purl.org/dc/terms/type
          :license, # http://purl.org/dc/terms/rights
          :part_of, # http://purl.org/dc/terms/isPartOf
          :replaces, # http://purl.org/dc/terms/replaces
          :resource_type, # http://purl.org/dc/terms/type
          :title, # http://purl.org/dc/terms/title
          :type, # http://purl.org/dc/terms/type
          :contributor, # http://purl.org/dc/elements/1.1/contributor
          :coverage, # http://purl.org/dc/elements/1.1/coverage
          :creator, # http://purl.org/dc/elements/1.1/creator
          :date, # http://purl.org/dc/elements/1.1/date
          :description, # http://purl.org/dc/elements/1.1/description
          :keyword, # http://purl.org/dc/elements/1.1/relation
          :language, # http://purl.org/dc/elements/1.1/language
          :local_identifier, # http://purl.org/dc/elements/1.1/identifier
          :publisher, # http://purl.org/dc/elements/1.1/publisher
          :rights_note, # http://purl.org/dc/elements/1.1/rights
          :source, # http://purl.org/dc/elements/1.1/source
          :subject, # http://purl.org/dc/elements/1.1/subject
          :rights_statement, # http://www.europeana.eu/schemas/edm/rights
          :portion_note, # http://www.w3.org/2004/02/skos/core#scopeNote
          :edition, # http://id.loc.gov/ontologies/bibframe/editionStatement
          :geographic_origin, # http://id.loc.gov/ontologies/bibframe/originPlace
          :series, # Local
          :pdf_type, # Local
          :container, # Local
          :rendered_rights_statement # Local

  display_in_manifest displayed_attributes
  suppress_from_manifest Schema::IIIF.attributes,
                         :visibility,
                         :internal_resource,
                         :rights_statement,
                         :rendered_rights_statement,
                         :thumbnail_id

  # TODO: Rename to decorated_members
  def members
    wayfinder.decorated_members
  end

  # TODO: Rename to decorated_file_sets
  def file_sets
    wayfinder.decorated_file_sets
  end

  # TODO: Rename to decorated_simple_resources
  def simple_resource_members
    wayfinder.decorated_simple_resources
  end

  # TODO: Rename to decorated_collections
  def parents
    wayfinder.decorated_collections
  end
  alias collections parents

  # TODO: Rename to decorated_parent
  def decorated_parent_resource
    wayfinder.decorated_parent
  end

  def rendered_rights_statement
    rights_statement.map do |rights_statement|
      term = ControlledVocabulary.for(:rights_statement).find(rights_statement)
      next unless term
      h.link_to(term.label, term.value) +
        h.content_tag("br") +
        h.content_tag("p") do
          term.definition.html_safe
        end +
        h.content_tag("p") do
          I18n.t("works.show.attributes.rights_statement.boilerplate").html_safe
        end
    end
  end

  def manageable_structure?
    false
  end

  def attachable_objects
    [SimpleResource]
  end

  def collection_slugs
    @collection_slugs ||= collections.flat_map(&:slug)
  end

  delegate :human_readable_type, to: :model

  def created
    output = super
    return if output.blank?
    output.map { |value| Date.parse(value.to_s).strftime("%B %-d, %Y") }
  end
end
