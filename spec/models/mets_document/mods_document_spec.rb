# frozen_string_literal: true
require "rails_helper"

RSpec.describe METSDocument::MODSDocument do
  subject(:mods_document) { described_class.from(mets: mets, xpath: xpath) }

  let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4609321-s42.mets") }
  let(:mets) { File.open(mets_file) { |f| Nokogiri::XML(f) } }
  let(:xpath) { "/mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods" }

  context "pudl0036" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0036-135-01.mets") }
    describe "attributes" do
      it "returns known values for each attribute" do
        expect(mods_document.title).to eq ["Our \"Surplus\" is not in Cash"]
        expect(mods_document.creator).to eq ["Interborough Rapid Transit Company"]
        expect(mods_document.type_of_resource).to eq ["still image"]
        expect(mods_document.genre).to eq ["posters"]
        expect(mods_document.geographic_origin).to eq ["New York (N.Y.)"]
        expect(mods_document.date_created).to eq ["1920-02"]
        expect(mods_document.language).to eq ["eng"]
        expect(mods_document.extent).to eq ["1 poster; approximately 21 × 16 inches"]
        expect(mods_document.abstract).to eq [
          "Advertising poster for the Interborough Rapid Transit Company of New York City, discussing the three different ways in which the fare \"surplus\" is allocated. No illustration"
        ]
        expect(mods_document.subject).to contain_exactly "Advertising", "Subways", "Posters", "Lee, Ivy L. (Ivy Ledbetter), 1877-1934", "New York (N.Y.)"
        expect(mods_document.series).to eq ["The Subway Sun. Volume 3. Number 6"]
        expect(mods_document.access_condition).not_to be_blank
        expect(mods_document.holding_simple_sublocation).to eq ["Mudd"]
        expect(mods_document.shelf_locator).to eq ["Mudd, MC085. Box 135"]
        finding_aid_identifier = mods_document.finding_aid_identifier.first
        expect(finding_aid_identifier.identifier).to eq "http://arks.princeton.edu/ark:/88435/m039k489x"
        expect(finding_aid_identifier.title).to eq "Ivy Ledbetter Lee Papers, 1881-1989 (bulk 1915-1946)"
        expect(mods_document.replaces).to eq "http://pudl.princeton.edu/objects/4d52d496-f15e-405d-863b-32fb880f13d8"
      end
    end
  end

  context "pudl0100" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0100-lc-egx_0003.mets") }
    describe "attributes" do
      it "returns known values for each attribute" do
        expect(mods_document.title).to eq [RDF::Literal.new("الاختيار", language: "ara-Arab")]
        expect(mods_document.actor).to contain_exactly(
          Grouping.new(
            elements: [
              RDF::Literal.new("Ḥusnī, Suʻād", language: "ara-Latn"),
              RDF::Literal.new("سعاد حسني", language: "ara-Arab")
            ]
          ),
          Grouping.new(
            elements: [
              RDF::Literal.new("ʻAlāyilī, ʻIzzat, 1934-", language: "ara-Latn"),
              RDF::Literal.new("عزت العلايلي", language: "ara-Arab")
            ]
          ),
          RDF::Literal.new("هدى سلطان", language: "ara-Arab"),
          Grouping.new(
            elements: [
              RDF::Literal.new("Milījī, Maḥmūd", language: "ara-Latn"),
              RDF::Literal.new("محمود المليجي", language: "ara-Arab")
            ]
          ),
          "Test"
        )
        expect(mods_document.director).to contain_exactly(
          RDF::Literal.new("يوسف شاهين", language: "ara-Arab")
        )
        expect(mods_document.type_of_resource).to eq ["still image"]
        expect(mods_document.genre).to eq ["Lobby Cards"]
        expect(mods_document.geographic_origin).to eq ["Egypt"]
        expect(mods_document.language).to eq ["ara"]
        expect(mods_document.extent).to eq ["4 pieces ; approximately 50 x 37 cm."]
        expect(mods_document.local_identifier).to eq ["egx-0003"]
        expect(mods_document.date_created).to eq ["1901 - 2000"]
        expect(mods_document.shelf_locator).to eq ["Curator's office, Cabinet 11/06"]
      end
    end
  end

  context "pudl0001" do
    let("mets_file") { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4612596.mets") }
    it "returns date issued" do
      expect(mods_document.date_issued).to eq "1470,1475"
    end
  end

  context "pudl0017" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0017-wc064.mets") }
    describe "attributes" do
      it "returns known values for each attribute" do
        expect(mods_document.title).to eq ["City Hall after the earthquake, San Francisco, California"]
        expect(mods_document.type_of_resource).to eq ["still image"]
        expect(mods_document.photographer).to eq ["Underwood & Underwood"]
        expect(mods_document.genre).to eq ["Lantern slides", "Cityscape photographs"]
        expect(mods_document.geographic_origin).to eq ["California", "San Francisco (Calif.)"]
        expect(mods_document.date_created).to eq ["1906"]
        expect(mods_document.extent).to eq ["7 × 7.5 cm."]
        expect(mods_document.note).to eq [
          "Typescript notation on the recto reads \"284--8189 - After the earthquake, San Francisco, Cal.\" In a mount measuring 8 × 10 cm." \
          " Title supplied by cataloger and derived from caption; attribution from printed caption."
        ]
        expect(mods_document.subject).to eq ["San Francisco Earthquake and Fire, Calif., 1906", "Natural disasters", "Architecture"]
        expect(mods_document.local_identifier).to eq ["WA 1998:223"]
        expect(mods_document.holding_simple_sublocation).to eq ["WA"]
        expect(mods_document.shelf_locator).to eq ["WA, (WA) WC064, H0030"]
        expect(mods_document.finding_aid_identifier).to eq []
        expect(mods_document.replaces).to eq nil
      end
    end
  end

  context "pudl0038" do
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-mp090-0894.mets") }
    describe "attributes" do
      it "returns coordinates as a CoveragePoint and TitleWithSubtitle" do
        expect(mods_document.title.first).to be_a TitleWithSubtitle
        expect(mods_document.title.first.to_s).to eq "Henry Hall: Rendering"
        expect(mods_document.subject).not_to include "40.345827/-74.660627"
        expect(mods_document.coverage_point.first).to be_a CoveragePoint
        expect(mods_document.coverage_point.first.lat).to eq 40.345827
        expect(mods_document.coverage_point.first.lon).to eq(-74.660627)
      end
    end
  end

  context "pudl0009" do
    describe "attributes" do
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0009-1-0001.mets") }
      it "returns title with the nonSort value" do
        expect(mods_document.title).to eq("The Chapel, Princeton University")
      end
      it "returns sort title without the non_sort value" do
        expect(mods_document.sort_title).to eq("Chapel, Princeton University")
      end

      it "returns the publisher" do
        expect(mods_document.publisher).to include "Published by H. M. Hinkson, Stationer, Princeton, N. J. - The Albertype Co.,"
      end
      it "returns date published" do
        expect(mods_document.date_published).to eq "1941,1950"
      end
    end

    describe "attributes" do
      let("mets_file") { Rails.root.join("spec", "fixtures", "mets", "pudl0009-1-0144.mets") }
      it "returns copyright date" do
        expect(mods_document.date_copyright).to eq "1903"
      end
      it "will not return sort_title" do
        expect(mods_document.sort_title).to eq nil
      end
      it "will return title" do
        expect(mods_document.title).to eq ["Prospect President's Residence, Princeton University"]
      end
    end
  end

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
      expect(mods_document.subject).to include "Fitzgerald, F. Scott (Francis Scott), 1896-1940"
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
      expect(mods_document.shelf_locator).to contain_exactly "Mudd, Box AD01, Item 7350"
    end
  end

  describe "#collection_code" do
    before { stub_ezid(shoulder: "88435", blade: "ww72bb49w", location: "http://findingaids.princeton.edu/collections/AC111") }
    let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-7350.mets") }
    it "accesses the extracts the collection number from the ark" do
      expect(mods_document.collection_code).to eq "AC111"
    end
  end
end
