# frozen_string_literal: true
require "rails_helper"

RSpec.describe CSVReport do
  describe "#write" do
    it "can convert an array of ephemera terms" do
      parent_vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary, label: "Grandparent")
      vocabulary = FactoryBot.create_for_repository(:ephemera_vocabulary, member_of_vocabulary_id: parent_vocabulary.id, label: "Parent")
      FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: vocabulary.id, label: "Test Term", uri: "https://bla.com", code: "test", tgm_label: "TGM Bla", lcsh_label: "Bla")

      resources = ChangeSetPersister.default.query_service.find_all_of_model(model: EphemeraTerm)

      report = described_class.new(resources.lazy, fields: [:vocabulary_breadcrumbs, :label, :uri, :code, :tgm_label, :lcsh_label])
      report.write(path: Rails.root.join("tmp", "csv_test.csv"))
      read = CSV.read(Rails.root.join("tmp", "csv_test.csv"), headers: true, header_converters: :symbol)

      expect(read.length).to eq 1
      expect(read[0].to_h).to eq(
        {
          vocabulary_breadcrumbs: "Grandparent | Parent",
          label: "Test Term",
          uri: "https://bla.com",
          code: "test",
          tgm_label: "TGM Bla",
          lcsh_label: "Bla"
        }
      )
    end

    it "converts an array of resources to a CSV and writes it to a path" do
      stub_catalog(bib_id: "991234563506421")
      stub_ezid(shoulder: "99999/fk4", blade: "")
      file_set = FactoryBot.create_for_repository(:file_set)
      collection = FactoryBot.create_for_repository(:collection, title: "Test Collection")
      resources = [FactoryBot.create_for_repository(
        :complete_scanned_resource,
        member_ids: [file_set.id],
        member_of_collection_ids: [collection.id],
        source_metadata_identifier: "991234563506421",
        import_metadata: true,
        series: ["First", "Second"]
      )]

      # Lazy isn't necessary, but should be able to work.
      report = described_class.new(resources.lazy, fields: [:title, :source_metadata_identifier, :identifier, :visibility, :state, :call_number, :extent, :series, :collections, :file_count])

      expect(report.csv_rows.first.to_h[:identifier]).to eq resources[0].identifier[0]
      expect(report.csv_rows.first.to_h[:title]).to eq "Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord."
      expect(report.csv_rows.first.to_h[:call_number]).to eq "BL980.G7 B66 1982"
      expect(report.headers).to eq ["Title", "Source metadata identifier", "Identifier", "Visibility", "State", "Call number", "Extent", "Series", "Collections", "File count"]

      report.write(path: Rails.root.join("tmp", "csv_test.csv"))
      read = CSV.read(Rails.root.join("tmp", "csv_test.csv"), headers: true, header_converters: :symbol)
      expect(read.length).to eq 1
      expect(read[0].to_h).to eq(
        {
          title:
          "Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.",
          source_metadata_identifier: "991234563506421",
          identifier: "ark:/99999/fk4",
          visibility: "open",
          state: "complete",
          call_number: "BL980.G7 B66 1982",
          extent: "xiv, 273 p. : ill. ; 24 cm.",
          series: "First, Second",
          collections: "Test Collection",
          file_count: "1"
        }
      )
    end
  end
end
