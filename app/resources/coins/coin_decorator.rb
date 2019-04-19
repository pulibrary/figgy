# frozen_string_literal: true
class CoinDecorator < Valkyrie::ResourceDecorator
  display :coin_number,
          :weight,
          :holding_location,
          :size,
          :die_axis,
          :technique,
          :counter_stamp,
          :analysis,
          :public_note,
          :private_note,
          :rights_statement,
          :find_place,
          :find_number,
          :find_date,
          :find_locus,
          :find_feature,
          :find_description,
          :citations,
          :numismatic_collection,
          :rendered_accession,
          :number_in_accession,
          :provenance,
          :loan,
          :replaces,
          :visibility,
          :append_id

  delegate :members, :decorated_file_sets, :decorated_parent, :decorated_numismatic_accession, to: :wayfinder
  delegate :id, :label, to: :accession, prefix: true

  def ark_mintable_state?
    false
  end

  def citations
    numismatic_citation.map { |c| c.decorate.title }
  end

  def pub_created_display
    [decorated_parent.ruler, decorated_parent.denomination&.first, decorated_parent.decorated_numismatic_place&.city].compact.join(", ") if decorated_parent
  end

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def orangelight_id
    "coin-#{coin_number}"
  end

  def call_number
    "Coin #{coin_number}"
  end

  def rendered_accession
    decorated_numismatic_accession&.label
  end

  def state
    super.first
  end

  def pdf_file
    pdf = file_metadata.find { |x| x.mime_type == ["application/pdf"] }
    pdf if pdf && Valkyrie::StorageAdapter.find(:derivatives).find_by(id: pdf.file_identifiers.first)
  rescue Valkyrie::StorageAdapter::FileNotFound
    nil
  end
end
