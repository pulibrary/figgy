# frozen_string_literal: true
require "rails_helper"

describe PulMetadataServices::BibRecord do
  subject(:record) { described_class.new(source) }

  let(:bib_id) { "1160682" }
  let(:source) { file_fixture("files/catalog/#{bib_id}.mrx").read }

  before do
    stub_catalog(bib_id: "1160682")
    stub_catalog(bib_id: "7214786")
    stub_catalog(bib_id: "345682")
    stub_catalog(bib_id: "10068705")
  end

  describe "#formatted_fields_as_array" do
    let(:fields) do
      [
        "240",
        "245",
        "246"
      ]
    end
    it "gets what you ask for with one" do
      expect(record.formatted_fields_as_array("245")).to eq ["The weeping angels"]
    end

    it "gets what you ask for with multiple" do
      expected = [
        "Angels take Manhattan",
        "The weeping angels",
        "Flesh and stone"
      ]
      expect(record.formatted_fields_as_array(fields)).to eq expected
    end

    context "using the 650 field" do
      let(:bib_id) { "345682" }

      it "respects the separator option" do
        fields = ["650"]
        expected = ["International relations.", "World politics--1985-1995."]
        expect(record.formatted_fields_as_array(fields, separator: "--")).to eq expected
      end

      it "respects the codes option" do
        fields = ["650"]
        expected = ["International relations.", "World politics"]
        expect(record.formatted_fields_as_array(fields, codes: ["a"])).to eq expected
      end
    end

    context "with linked fields" do
      let(:bib_id) { "1160682b" }

      it "extracts the values from the linked fields" do
        expect(record.formatted_fields_as_array(fields)).to include "test uniform title"
      end
    end
  end

  describe "#attributes" do
    it "works" do
      expected = {
        title: ["The weeping angels"],
        sort_title: "weeping angels",
        creator: ["Moffat, Steven."],
        date_created: "1899",
        publisher: ["A. Martínez,"]
      }
      expect(record.attributes).to eq expected
    end
  end

  describe "#alternative_titles" do
    it "gets the other titles" do
      expected = [
        "Angels take Manhattan",
        "Flesh and stone"
      ]
      expect(record.alternative_titles).to eq expected
    end

    context "with linked fields" do
      let(:bib_id) { "1160682b" }

      it "gets the other titles" do
        expect(record.alternative_titles).to include "פסין, אהרן יהושע."
      end
    end
  end

  describe "#abstract" do
    it "extracts the abstract" do
      expect(record.abstract).to eq ["Fish fingers and custard!"]
    end
  end

  describe "#audience" do
    it "extracts the audience" do
      expect(record.audience).to eq ["7 & up."]
    end
  end

  describe "#citation" do
    it "extracts the citation" do
      expect(record.citation).to eq ["test citation"]
    end
  end

  describe "#contributors" do
    let(:bib_id) { "345682" }

    it "extracts the contributor names for the resource" do
      expect(record.contributors).to eq ["White, Michael M.", "Smith, Bob F."]
    end

    context "when the field is linked" do
      let(:bib_id) { "345682b" }

      it "extracts the values from the linked field" do
        expect(record.contributors).to include "test linked contributor"
      end
    end
  end

  describe "#creator" do
    it "gets it from the 100" do
      expect(record.creator).to eq ["Moffat, Steven."]
    end

    context "with non-latin characters" do
      let(:bib_id) { "7214786" }
      it "includes the 880 version if there is one" do
        expect(record.creator).to eq ["Pesin, Aharon Yehoshuʻa.", "פסין, אהרן יהושע."]
      end
    end
  end

  describe "#date" do
    it "seems to work (there are infinite possibilities)" do
      expect(record.date).to eq "1899"
    end
  end

  describe "#description" do
    it "extracts the description" do
      expect(record.description).to eq ["test description"]
    end
  end

  describe "#extent" do
    it "extracts the extent" do
      expect(record.extent).to eq ["236, [3] p. 19 cm."]
    end
  end

  describe "#parts" do
    let(:bib_id) { "345682" }

    it "retrieves 7xxs with ts" do
      expect(record.parts).to include "Jones, Martha. The doctor's daughter."
    end

    context "with a 740 field" do
      let(:bib_id) { "10068705" }

      it "retrieves 740 field values" do
        expect(record.parts).to eq ["Price list 1943"]
      end
    end

    context "with a 730 field" do
      it "retrieves 730 field values" do
        expect(record.parts).to eq ["Jones, Martha. The doctor's daughter.", "Test Part"]
      end
    end
  end

  describe "#language_codes" do
    it "extracts the language code" do
      expect(record.language_codes).to eq ["spa"]
    end

    context "with a non-English language code" do
      let(:bib_id) { "7214786" }

      it "extracts the language code" do
        expect(record.language_codes).to eq ["heb"]
      end
    end

    context "with multiple language codes" do
      let(:bib_id) { "345682" }

      it "extracts the language codes" do
        expect(record.language_codes).to eq ["eng", "dut"]
      end
    end

    context "with three-character language codes" do
      let(:bib_id) { "345682c" }

      it "extracts each language code" do
        expect(record.language_codes).to eq ["eng", "dut", "lat", "ave", "eus", "bre"]
      end
    end
  end

  describe "#provenance" do
    let(:bib_id) { "1160682" }
    it "extracts the provenance" do
      expect(record.provenance).to eq ["test provenance"]
    end
  end

  describe "#rights" do
    let(:bib_id) { "345682" }
    it "extracts the rights" do
      expect(record.rights).to eq ["test rights"]
    end
  end

  describe "#sort_title" do
    it "gets it" do
      expect(record.sort_title).to eq "weeping angels"
    end
  end

  describe "#series" do
    let(:bib_id) { "10068705" }
    it "extracts the series" do
      expect(record.series).to eq ["volume"]
    end
  end

  describe "#title" do
    it "gets it" do
      expect(record.title).to eq ["The weeping angels"]
    end

    context "with multiple titles" do
      let(:bib_id) { "7214786" }

      it "extracts the values" do
        expect(record.title).to eq [
          "Be-darkhe avot : ʻiyun be-darke ha-avot ṿe-hanhagotehem be-ḳiyum ha-Torah ʻod li-fene she-nitnah",
          "בדרכי אבות : עיון בדרכי האבות והנהגותיהם בקיום התורה עוד לפני שניתנה"
        ]
      end
    end

    context "with a linked field" do
      let(:bib_id) { "7214786" }
      let(:include_initial_article) { false }

      it "extracts the values without an initial article" do
        expect(record.title(include_initial_article)).to eq [
          "Be-darkhe avot : ʻiyun be-darke ha-avot ṿe-hanhagotehem be-ḳiyum ha-Torah ʻod li-fene she-nitnah",
          "בדרכי אבות : עיון בדרכי האבות והנהגותיהם בקיום התורה עוד לפני שניתנה"
        ]
      end
    end

    context "with only a 246 field" do
      let(:bib_id) { "4609321b" }

      it "extracts the values" do
        expect(record.title).to eq ["Bible. Latin. Vulgate. 1456."]
      end
    end

    context "with only a linked 246 field" do
      let(:bib_id) { "4609321c" }

      it "extracts the values" do
        expect(record.title).to eq ["Bible. Latin. Vulgate. 1456.", "פסין, אהרן יהושע."]
      end
    end
  end

  describe "#subjects" do
    it "extracts the subjects" do
      expect(record.subjects).to eq ["Cuba--History--Revolution, 1895-1898."]
    end
  end

  describe "#contents" do
    it "gets the 505s as one squashed string" do
      expect(record.contents).to eq "Contents / foo."
    end

    context "with a linked field" do
      let(:bib_id) { "1160682b" }
      it "also extracts any fields linked to 505 fields" do
        expect(record.contents).to include "= test linked contents"
      end
    end
  end
end
