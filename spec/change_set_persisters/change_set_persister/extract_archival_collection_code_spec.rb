# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::ExtractArchivalCollectionCode do
  subject(:hook) { described_class }

  describe "#extract_collection_code" do
    it "can handle lots of variants" do
      expect(hook.extract_collection_code("RCPXG-5830371.2_c0001")).to eq "RCPXG-5830371.2"
      expect(hook.extract_collection_code("C0744.04_c0082")).to eq "C0744.04"
      expect(hook.extract_collection_code("C0723.1-47_c0276")).to eq "C0723.1-47"
      expect(hook.extract_collection_code("C0723.306e_c013")).to eq "C0723.306e"
      expect(hook.extract_collection_code("MC001.03.03_c0171")).to eq "MC001.03.03"
      expect(hook.extract_collection_code("MC016/c11318")).to eq "MC016"
      expect(hook.extract_collection_code("MC001")).to eq "MC001"
    end
  end
end
