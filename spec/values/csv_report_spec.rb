# frozen_string_literal: true
require "rails_helper"

RSpec.describe CSVReport do
  describe "#write" do
    it "converts an array of resources to a CSV and writes it to a path" do
      stub_catalog(bib_id: "123456")
      stub_ezid(shoulder: "99999/fk4", blade: "")
      resources = [FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "123456", import_metadata: true)]

      # Lazy isn't necessary, but should be able to work.
      report = described_class.new(resources.lazy, fields: [:title, :source_metadata_identifier, :identifier, :visibility, :state, :call_number, :extent])

      expect(report.csv_rows.first.to_h[:identifier]).to eq resources[0].identifier[0]
      expect(report.csv_rows.first.to_h[:title]).to eq "Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord."
      expect(report.csv_rows.first.to_h[:call_number]).to eq "BL980.G7 B66 1982"
      expect(report.headers).to eq ["Title", "Source metadata identifier", "Identifier", "Visibility", "State", "Call number", "Extent"]

      report.write(path: Rails.root.join("tmp", "csv_test.csv"))
      read = CSV.read(Rails.root.join("tmp", "csv_test.csv"), headers: true, header_converters: :symbol)
      expect(read.length).to eq 1
      expect(read[0].to_h).to eq(
        {
          title:
          "Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.",
          source_metadata_identifier: "123456",
          identifier: "ark:/99999/fk4",
          visibility: "open",
          state: "complete",
          call_number: "BL980.G7 B66 1982",
          extent: "xiv, 273 p. : ill. ; 24 cm."
        }
      )
    end
  end
end
