# frozen_string_literal: true
require "rails_helper"

describe RemoteRecord::Catalog do
  let(:content_type_marc_xml) { "application/marcxml+xml" }

  before do
    stub_catalog(bib_id: "9946093213506421", content_type: content_type_marc_xml)
  end

  describe "#marcxml" do
    let(:id) { "9946093213506421" }
    let(:source) { file_fixture("files/catalog/9946093213506421.mrx").read }
    it "returns marcxml" do
      expect(described_class.new(id).marcxml).to eq source
    end
  end
end
