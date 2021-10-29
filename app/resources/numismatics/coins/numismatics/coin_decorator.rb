# frozen_string_literal: true
module Numismatics
  class CoinDecorator < Valkyrie::ResourceDecorator
    display :coin_number,
            :weight,
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

    delegate :decorated_file_sets,
             :decorated_find_place,
             :decorated_numismatic_accession,
             :decorated_parent,
             :members,
             :parent,
             to: :wayfinder

    delegate :id, :label, to: :accession, prefix: true

    def find_number
      Array.wrap(super.to_s)
    end

    def call_number
      "Coin #{coin_number}"
    end

    def citations
      numismatic_citation.map { |c| c.decorate.title }
    end

    def find_place
      decorated_find_place&.title
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

    def pdf_file
      pdf = file_metadata.find { |x| x.mime_type == ["application/pdf"] }
      pdf if pdf && Valkyrie::StorageAdapter.find(:derivatives).find_by(id: pdf.file_identifiers.first)
    rescue Valkyrie::StorageAdapter::FileNotFound
      nil
    end

    def loan
      super.map { |l| l.decorate.title }
    end

    def provenance
      super.map { |p| p.decorate.title }
    end

    def pub_created_display
      [decorated_parent.rulers&.first, decorated_parent.denomination&.first, decorated_parent.decorated_numismatic_place&.city].compact.join(", ") if decorated_parent
    end

    def rendered_accession
      decorated_numismatic_accession&.label
    end

    def state
      super.first
    end

    def weight_label
      ["#{weight} in grams"] if weight
    end

    def size_label
      ["#{size} in mm"] if size
    end

    def weight
      Array.wrap(super).first
    end

    def size
      Array.wrap(super).first
    end
  end
end
