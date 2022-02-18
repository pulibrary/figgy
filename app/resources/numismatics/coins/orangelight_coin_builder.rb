# frozen_string_literal: true

class OrangelightCoinBuilder
  include ThumbnailHelper

  attr_reader :decorator, :parent
  def initialize(decorator)
    @decorator = decorator
    @parent = decorator.decorated_parent
  end

  def build
    clean_document(document_hash)
  end

  private

    def coin_builder_error
      {error: "#{decorator.title.first} with id: #{decorator.id} has no parent numismatic issue and cannot build an OL document."}
    end

    def clean_document(hash)
      raise NoParentException, coin_builder_error.to_json if hash.nil?

      hash.delete_if do |_k, v|
        v.nil? || v.try(:empty?)
      end
    end

    def document_hash
      document_coin_hash.merge(document_parent_hash) if document_parent_hash.present?
    end

    def document_coin_hash
      {
        id: decorator.orangelight_id,
        title_display: "Coin: #{decorator.coin_number}",
        pub_created_display: decorator.pub_created_display,
        access_facet: ["Online", "In the Library"],
        call_number_display: [decorator.call_number],
        call_number_browse_s: [decorator.call_number],
        location_code_s: [coin_location_code],
        location: [coin_library_location],
        location_display: [coin_full_location],
        format: ["Coin"],
        advanced_location_s: [coin_location_code],
        counter_stamp_s: decorator.counter_stamp,
        analysis_s: initial_capital(decorator.analysis),
        notes_display: initial_capital(decorator.public_note),
        find_place_s: [decorator.find_place],
        find_date_s: decorator.find_date,
        find_feature_s: decorator.find_feature,
        find_locus_s: decorator.find_locus,
        find_number_s: decorator.find_number,
        find_description_s: decorator.find_description,
        die_axis_s: decorator.die_axis,
        size_s: decorator.size_label,
        technique_s: decorator.technique,
        weight_s: decorator.weight_label,
        holdings_1display: holdings_hash,
        coin_references_s: decorator.citations,
        coin_references_sort: decorator.citations&.first,
        numismatic_collection_s: decorator.numismatic_collection,
        numismatic_accession_s: [decorator.decorated_numismatic_accession&.indexed_label],
        numismatic_provenance_s: decorator.provenance
      }
    end

    def document_parent_hash
      return unless parent
      {
        pub_date_start_sort: parent.earliest_date&.first.to_i,
        pub_date_end_sort: parent.latest_date&.first.to_i,
        issue_object_type_s: parent.object_type,
        issue_denomination_s: parent.denomination,
        issue_denomination_sort: parent.denomination&.first,
        issue_number_s: parent.issue_number.to_s,
        issue_metal_s: initial_capital(parent.metal),
        issue_metal_sort: parent.metal&.first,
        issue_shape_s: parent.shape,
        issue_color_s: parent.color,
        issue_edge_s: parent.edge,
        issue_era_s: initial_capital(parent.era),
        issue_ruler_s: parent.rulers,
        issue_ruler_sort: parent.rulers&.first,
        issue_master_s: [parent.master],
        issue_workshop_s: parent.workshop,
        issue_series_s: parent.series,
        issue_place_s: [parent.rendered_place],
        issue_city_s: [parent.city],
        issue_state_s: [parent.geo_state],
        issue_region_s: [parent.region],
        issue_place_sort: parent.rendered_place,
        issue_obverse_description_s: parent.obverse_description,
        issue_obverse_figure_s: initial_capital(parent.obverse_figure),
        issue_obverse_symbol_s: parent.obverse_symbol,
        issue_obverse_part_s: parent.obverse_part,
        issue_obverse_orientation_s: parent.obverse_orientation,
        issue_obverse_figure_description_s: parent.obverse_figure_description,
        issue_obverse_figure_relationship_s: parent.obverse_figure_relationship,
        issue_obverse_legend_s: parent.obverse_legend,
        issue_obverse_attributes_s: parent.obverse_attributes,
        issue_reverse_description_s: parent.reverse_description,
        issue_reverse_figure_s: initial_capital(parent.reverse_figure),
        issue_reverse_symbol_s: parent.reverse_symbol,
        issue_reverse_part_s: parent.reverse_part,
        issue_reverse_orientation_s: parent.reverse_orientation,
        issue_reverse_figure_description_s: parent.reverse_figure_description,
        issue_reverse_figure_relationship_s: parent.reverse_figure_relationship,
        issue_reverse_legend_s: parent.reverse_legend,
        issue_reverse_attributes_s: parent.reverse_attributes,
        issue_references_s: parent.citations,
        issue_references_sort: parent.citations&.first,
        issue_artists_s: parent.artists,
        issue_artists_sort: parent.artists&.first,
        issue_monogram_title_s: parent.decorated_numismatic_monograms.map(&:title),
        issue_monogram_1display: parent.decorated_numismatic_monograms.map { |m| monogram_hash(m) }.to_json.to_s,
        issue_subjects_s: parent.subjects,
        issue_date_s: [parent.date_range]
      }
    end

    def holdings_hash
      {
        "numismatics" => {
          "location" => coin_full_location,
          "library" => coin_library_location,
          "location_code" => coin_location_code,
          "call_number" => decorator.call_number,
          "call_number_browse" => decorator.call_number
        }
      }.to_json.to_s
    end

    def monogram_hash(monogram)
      {
        title: monogram.title,
        document_id: monogram.id.to_s
      }
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def coin_location_code
      "rare$num"
    end

    def coin_library_location
      "Special Collections"
    end

    def coin_full_location
      "Special Collections - Numismatics Collection"
    end

    def initial_capital(value)
      return unless value
      return value.map(&:upcase_first) if value.is_a? Array
    end

    class NoParentException < StandardError; end
end
