# frozen_string_literal: true
module Numismatics
  class IssueDecorator < Valkyrie::ResourceDecorator
    display :object_type,
            :denomination,
            :metal,
            :shape,
            :color,
            :edge,
            :object_date,
            :era,
            :earliest_date,
            :latest_date,
            :rulers,
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
            :artists,
            :citations,
            :notes,
            :subjects,
            :member_of_collections,
            :replaces,
            :visibility

    display_in_manifest displayed_attributes
    suppress_from_manifest Schema::IIIF.attributes,
                           :visibility,
                           :internal_resource,
                           :thumbnail_id

    delegate :coin_count,
             :decorated_coins,
             :decorated_file_sets,
             :decorated_numismatic_monograms,
             :decorated_numismatic_place,
             :decorated_master,
             :decorated_rulers,
             :members,
             to: :wayfinder

    # Don't mink ARKs for Numismatics::Issues
    def ark_mintable_state?
      false
    end

    def artists
      numismatic_artist.map { |a| a.decorate.title }
    end

    def attachable_objects
      [Numismatics::Coin]
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
      false
    end

    def manageable_structure?
      false
    end

    def manageable_order?
      true
    end

    def master
      decorated_master&.title
    end

    def notes
      numismatic_note.map { |a| a.decorate.title }
    end

    def obverse_attributes
      obverse_attribute.map { |a| a.decorate.title }
    end

    def rendered_place
      decorated_numismatic_place&.title
    end

    def reverse_attributes
      reverse_attribute.map { |a| a.decorate.title }
    end

    def rulers
      decorated_rulers.map(&:title)
    end

    def state
      super.first
    end

    def subjects
      numismatic_subject.map { |s| s.decorate.title }
    end
  end
end
