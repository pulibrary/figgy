# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumScannedMapImporterJob do
  describe ".perform" do
    it "delegates out to PlumScannedMapImporter" do
      plum_scanned_map_importer = instance_double(PlumImporter, import!: instance_double(ScannedMap, id: "test"))
      allow(PlumScannedMapImporter).to receive(:new).and_return(plum_scanned_map_importer)

      described_class.perform_now("test")

      expect(PlumScannedMapImporter).to have_received(:new).with(id: "test", change_set_persister: anything)
      expect(plum_scanned_map_importer).to have_received(:import!)
    end
  end
end
