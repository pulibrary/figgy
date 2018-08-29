# frozen_string_literal: true
require "rails_helper"

RSpec.describe METSDocument::MODSDocument do
  subject(:mods_document) { described_class.from(mets: mets, xpath: xpath) }

  let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4609321-s42.mets") }
  let(:mets) { File.open(mets_file) { |f| Nokogiri::XML(f) } }
  let(:xpath) { "/mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods" }

  describe ".from" do
    it "constructs a MODSDocument from a METSDocument and an XPath" do
      expect(mods_document).to be_a described_class
    end
  end

  describe "#title" do
    it "accesses the title within the MODS-encoded metadata" do
      expect(mods_document.title).to include "Biblia Latina"
    end
  end

  describe "#alternative_title" do
    it "accesses the alternative titles within the MODS-encoded metadata" do
      expect(mods_document.alternative_title).to contain_exactly "Gutenberg Bible", "Mazarin Bible", "Mazarine Bible"
    end
  end

  describe "#uniform_title" do
    it "accesses the uniform title within the MODS-encoded metadata" do
      expect(mods_document.uniform_title).to include "Bible. Latin. 1456"
    end
  end

  describe "#date_created" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "tsop_typed.mets") }

    it "accesses the date of creation within the MODS-encoded metadata" do
      expect(mods_document.date_created).to include "1918"
    end
  end

  describe "#type_of_resource" do
    it "accesses the resource type within the MODS-encoded metadata" do
      expect(mods_document.type_of_resource).to include "text"
    end
  end

  describe "#extent" do
    it "accesses the extent within the MODS-encoded metadata" do
      expect(mods_document.extent).to include "2 v. (324; 319 leaves) ; 40.5 × 28.8 cm. (fol.)"
    end
  end

  describe "#access_condition" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "tsop_typed.mets") }

    it "accesses the access conditions within the MODS-encoded metadata" do
      expect(mods_document.access_condition).not_to be_empty
      expect(mods_document.access_condition.first).to include "Not to be published, reproduced"
    end
  end

  describe "#restriction_on_access" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "tsop_typed.mets") }

    it "accesses the access restrictions within the MODS-encoded metadata" do
      expect(mods_document.restriction_on_access).not_to be_empty
      expect(mods_document.restriction_on_access.first).to include "For legal and conservation reasons, access to F."
    end
  end

  context "when the URIs are encoded for access conditions and restrictions" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4609321-s42.mets") }

    describe "#access_condition" do
      it "accesses the access conditions within the MODS-encoded metadata" do
        expect(mods_document.access_condition).to include "http://www.princeton.edu/~rbsc/research/rights.html"
      end
    end

    describe "#restriction_on_access" do
      it "accesses the access restrictions within the MODS-encoded metadata" do
        expect(mods_document.restriction_on_access).to include "http://www.princeton.edu/~rbsc/research/rules.html"
      end
    end
  end

  describe "#note" do
    it "accesses the note within the MODS-encoded metadata" do
      expect(mods_document.note).to include "Commonly known in English as Gutenberg Bible, formerly known as Mazarin or Mazarine Bible."
    end
  end

  describe "#subject" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "tsop_typed.mets") }

    it "accesses the title within the MODS-encoded metadata" do
      expect(mods_document.subject).to include "F. Scott (Francis Scott)"
    end
  end

  describe "#abstract" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4612596.mets") }

    it "accesses the abstract within the MODS-encoded metadata" do
      expect(mods_document.abstract).not_to be_empty
      expect(mods_document.abstract.first).to include "Although printed with the same type as the Scheide fragment Goff D-325a, this fragment clearly belongs"
    end
  end

  describe "#table_of_contents" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "scrapbooks.mets") }

    it "accesses the title within the MODS-encoded metadata" do
      expect(mods_document.table_of_contents).to include "I. This Side of Paradise (1920)."
    end
  end

  describe "#genre" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }

    it "accesses genre fields" do
      expect(mods_document.genre).to contain_exactly "photographic prints"
    end
  end

  describe "#physical_location" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }

    it "accesses holding location from physicalLocation where type=text and holdingSimple > copyInformation > subLocation" do
      expect(mods_document.physical_location).to contain_exactly(
        "Princeton University Library. Department of Rare Books and Special Collections. Seeley G. Mudd Manuscript Library."
      )
    end
  end

  describe "#holding_simple_sublocation" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }

    it "accesses holding location from physicalLocation where type=text and holdingSimple > copyInformation > subLocation" do
      expect(mods_document.holding_simple_sublocation).to contain_exactly "Mudd"
    end
  end

  describe "#shelf_locator" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }

    it "accesses the shelfLocator field" do
      expect(mods_document.shelf_locator).to contain_exactly "Box AD01, Item 7350"
    end
  end
end
