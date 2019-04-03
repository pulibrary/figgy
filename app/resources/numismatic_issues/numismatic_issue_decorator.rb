# frozen_string_literal: true
class NumismaticIssueDecorator < Valkyrie::ResourceDecorator
  display :object_type,
          :denomination,
          :metal,
          :shape,
          :color,
          :edge,
          :object_date,
          :era,
          :rendered_date_range,
          :ruler,
          :rendered_place,
          :master,
          :workshop,
          :series,
          :obverse_figure,
          :obverse_part,
          :obverse_orientation,
          :obverse_figure_description,
          :obverse_figure_relationship,
          :obverse_symbol,
          :obverse_attributes,
          :obverse_legend,
          :reverse_figure,
          :reverse_part,
          :reverse_orientation,
          :reverse_figure_description,
          :reverse_figure_relationship,
          :reverse_symbol,
          :reverse_attributes,
          :reverse_legend,
          :decorated_numismatic_monograms,
          :note,
          :citations,
          :member_of_collections,
          :rendered_rights_statement,
          :subject,
          :replaces,
          :visibility

  display_in_manifest displayed_attributes
  suppress_from_manifest Schema::IIIF.attributes,
                         :visibility,
                         :internal_resource,
                         :rights_statement,
                         :rendered_rights_statement,
                         :thumbnail_id

  delegate :members, :decorated_file_sets, :decorated_coins, :coin_count, :decorated_numismatic_citations, :decorated_numismatic_artists, :decorated_numismatic_monograms, to: :wayfinder

  def attachable_objects
    [Coin]
  end

  def first_range
    @first_range ||= Array.wrap(date_range).map(&:decorate).first
  end

  def rendered_date_range
    return unless first_range.present?
    first_range.range_string
  end

  def citations
    citation.map { |c| c.decorate.title }
  end

  def artists
    decorated_numismatic_artists.map(&:title)
  end

  # Whether this box has a workflow state that grants access to its contents
  # @return [TrueClass, FalseClass]
  def grant_access_state?
    workflow_class.public_read_states.include? Array.wrap(state).first.underscore
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def rendered_place
    return if place.empty?
    place&.first&.decorate&.rendered_place
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

  def state
    super.first
  end
end
