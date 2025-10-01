# frozen_string_literal: true
require "csv"

namespace :figgy do
  namespace :report do
    desc "Write a CSV report of resources with MMS ids but findingaid ark targets"
    task ark_mismatches: :environment do
      ArkMismatchReporter.write
    end

    desc "Generate Nomisma RDF document"
    task nomisma: :environment do
      Nomisma.generate
    end

    desc "Write a CSV of LAE Subject terms"
    task lae_subjects: :environment do
      output = ENV["OUTPUT"]
      abort "usage: OUTPUT=output_path rake report:lae_subjects" unless output

      metadata_adapter = Valkyrie::MetadataAdapter.find(:indexing_persister)
      query_service = metadata_adapter.query_service

      vocab = query_service.custom_queries.find_ephemera_vocabulary_by_label(label: "Ephemera Subjects")
      terms = collect_terms(vocab)
      fields = %w[label code uri category]
      CSV.open(output, "w") do |csv|
        csv << fields
        terms.each do |term|
          csv << [
            term.label,
            term.code,
            term.decorate.uri.to_s,
            term.decorate.vocabulary.label
          ]
        end
      end
    end
  end

  def collect_terms(vocab)
    arr = []
    arr += vocab.decorate.terms
    vocab.decorate.categories.each do |category|
      arr += collect_terms(category)
    end
    arr
  end
end
