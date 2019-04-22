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
          :ce1,
          :ce2,
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
          :artists,
          :subjects,
          :member_of_collections,
          :rendered_rights_statement,
          :replaces,
          :visibility

  display_in_manifest displayed_attributes
  suppress_from_manifest Schema::IIIF.attributes,
                         :visibility,
                         :internal_resource,
                         :rights_statement,
                         :rendered_rights_statement,
                         :thumbnail_id

  delegate :coin_count,
           :decorated_coins,
           :decorated_file_sets,
           :decorated_numismatic_monograms,
           :decorated_numismatic_place,
           :decorated_master,
           :decorated_ruler,
           :members,
           to: :wayfinder

  def artists
    numismatic_artist.map { |a| a.decorate.title }
  end

  def attachable_objects
    [Coin]
  end

  def citations
    numismatic_citation.map { |c| c.decorate.title }
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

  def master
    decorated_master&.title
  end

  def rendered_place
    decorated_numismatic_place&.title
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

  def ruler
    decorated_ruler&.title
  end

  def state
    super.first
  end

  def subjects
    numismatic_subject.map { |s| s.decorate.title }
  end
end
