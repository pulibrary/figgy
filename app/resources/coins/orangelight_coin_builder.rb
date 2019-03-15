# frozen_string_literal: true

class OrangelightCoinBuilder
  attr_reader :decorator, :parent
  def initialize(decorator)
    @decorator = decorator
    @parent = decorator.decorated_parent
  end

  def build
    clean_document(document_hash)
  end

  private

    def clean_document(hash)
      hash.delete_if do |_k, v|
        v.nil? || v.try(:empty?)
      end
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def document_hash
      {
        id: decorator.orangelight_id,
        title_display: "Coin: #{decorator.coin_number}",
        pub_created_display: decorator.pub_created_display,
        access_facet: ["Online", "In the Library"],
        location: decorator.holding_location,
        format: ["Coin"],
        advanced_location_s: ["num"],
        counter_stamp_t: decorator.counter_stamp,
        analysis_t: decorator.analysis,
        notes_display: decorator.public_note,
        find_place_t: decorator.find_place,
        find_place_facet: decorator.find_place,
        find_date_t: decorator.find_date,
        find_feature_t: decorator.find_feature,
        find_locus_t: decorator.find_locus,
        find_number_t: decorator.find_number,
        find_description_t: decorator.find_description,
        die_axis_t: decorator.die_axis,
        size_t: decorator.size,
        technique_t: decorator.technique,
        weight_t: decorator.weight,
        pub_date_start_sort: parent.first_range&.start&.first.to_i,
        pub_date_end_sort: parent.first_range&.end&.first.to_i,
        issue_object_type_t: parent.object_type,
        issue_denomination_t: parent.denomination,
        issue_denomination_sort: parent.denomination&.first,
        issue_denomination_facet: parent.denomination,
        issue_number_s: parent.issue_number.to_s,
        issue_metal_t: parent.metal,
        issue_metal_sort: parent.metal&.first,
        issue_metal_facet: parent.metal,
        issue_shape_t: parent.shape,
        issue_color_t: parent.color,
        issue_edge_t: parent.edge,
        issue_era_t: parent.era,
        issue_ruler_t: parent.ruler,
        issue_ruler_sort: parent.ruler&.first,
        issue_master_t: parent.master,
        issue_workshop_t: parent.workshop,
        issue_series_t: parent.series,
        issue_place_t: [parent.rendered_place],
        issue_place_sort: parent.rendered_place,
        issue_place_facet: [parent.rendered_place],
        issue_obverse_figure_t: parent.obverse_figure,
        issue_obverse_symbol_t: parent.obverse_symbol,
        issue_obverse_part_t: parent.obverse_part,
        issue_obverse_orientation_t: parent.obverse_orientation,
        issue_obverse_figure_description_t: parent.obverse_figure_description,
        issue_obverse_figure_relationship_t: parent.obverse_figure_relationship,
        issue_obverse_legend_t: parent.obverse_legend,
        issue_obverse_attributes_t: parent.obverse_attributes,
        issue_reverse_figure_t: parent.reverse_figure,
        issue_reverse_symbol_t: parent.reverse_symbol,
        issue_reverse_part_t: parent.reverse_part,
        issue_reverse_orientation_t: parent.reverse_orientation,
        issue_reverse_figure_description_t: parent.reverse_figure_description,
        issue_reverse_figure_relationship_t: parent.reverse_figure_relationship,
        issue_reverse_legend_t: parent.reverse_legend,
        issue_reverse_attributes_t: parent.reverse_attributes,
        issue_references_t: parent.citations,
        issue_references_sort: parent.citations&.first,
        issue_artists_facet: parent.artists,
        issue_artists_t: parent.artists
      }
    end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
