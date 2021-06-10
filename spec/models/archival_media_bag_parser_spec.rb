# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaBagParser do
  let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
  let(:amb_parser) { described_class.new(path: bag_path, component_id: "C0652") }
  let(:barcode) { "32101047382401" }

  before do
    stub_aspace(pulfa_id: "C0652")
  end

  describe "#component_groups" do
    it { expect(amb_parser.component_groups.keys).to contain_exactly "C0652_c0377" }
  end

  describe "#pbcore_parser" do
    it { expect(amb_parser.pbcore_parser(barcode: barcode)).to be_a PbcoreParser }
  end

  describe "#image_file" do
    subject(:image_file) { amb_parser.image_file(barcode: barcode) }
    it { expect(image_file).to be_a ArchivalMediaBagParser::ImageFile }

    context "when the image file has a '.JPG' extension" do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "JPG_bag") }
      it "retrieves the file" do
        expect(amb_parser.image_file(barcode: barcode)).to be_a ArchivalMediaBagParser::ImageFile
      end
    end
  end

  describe "PbcoreParser" do
    describe "#barcode" do
      it { expect(amb_parser.pbcore_parser(barcode: barcode).barcode).to eq barcode }
    end

    describe "#transfer_notes" do
      let(:expected) do
        "Side A: Program in silence from approximately 00:12 until 04:06, speed fluctuates throughout program on tape; " \
          "Side B: Feedback heard throughout program on tape, gradual increass in speed throughout program on tape; "
      end
      it { expect(amb_parser.pbcore_parser(barcode: barcode).transfer_notes).to eq expected }
    end

    describe "#original_filename" do
      it { expect(amb_parser.pbcore_parser(barcode: barcode).original_filename).to eq "32101047382401.xml" }
    end

    describe "#main_title" do
      it "returns the title from pbcore" do
        expect(amb_parser.pbcore_parser(barcode: barcode).main_title).to eq "Interview: ERM / Jose Donoso (A2)"
      end
    end
  end

  describe "#valid?" do
    context "with a valid bag" do
      it "returns true" do
        expect(amb_parser.valid?).to eq true
      end
    end

    context "with a path to an invalid bag" do
      let(:bag_path) { Rails.root.join("spec", "fixtures", "bags", "invalid_bag") }
      let(:logger) { instance_double(Logger) }
      before do
        allow(logger).to receive(:error)
        allow(Logger).to receive(:new).and_return(logger)
      end

      it "returns false" do
        expect(amb_parser.valid?).to eq false
      end
    end
  end
end
