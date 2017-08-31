# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumImporterJob do
  describe ".perform" do
    it "delegates out to PlumImporter" do
      plum_importer = instance_double(PlumImporter, import!: instance_double(ScannedResource, id: "test"))
      allow(PlumImporter).to receive(:new).and_return(plum_importer)

      described_class.perform_now("test")

      expect(PlumImporter).to have_received(:new).with(id: "test", change_set_persister: anything)
      expect(plum_importer).to have_received(:import!)
    end
  end
end
