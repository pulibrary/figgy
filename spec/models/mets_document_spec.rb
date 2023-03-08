# frozen_string_literal: true
require "rails_helper"

RSpec.describe METSDocument do
  let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4612596.mets") }
  let(:mets_file_rtl) { Rails.root.join("spec", "fixtures", "mets", "pudl0032-ns73.mets") }
  let(:mets_file_multi) { Rails.root.join("spec", "fixtures", "mets", "pudl0001-4609321-s42.mets") }
  let(:mets_file_multi2) { Rails.root.join("spec", "fixtures", "mets", "pudl0058-616086.mets") }
  let(:mets_file_multi3) { Rails.root.join("spec", "fixtures", "mets", "pudl0134-170151.mets") }
  let(:mets_file_multi4) { Rails.root.join("spec", "fixtures", "mets", "pudl0058-3013164.mets") }
  let(:tight_bound_mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0075-6971526.mets") }
  let(:no_logical_order_mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0076-2538011.mets") }
  let(:tiff_file) { Rails.root.join("spec", "fixtures", "files", "example.tif") }
  let(:structure) do
    {
      nodes: [{
        label: "Title page", nodes: [{
          label: "Title page",
          proxy: "goszd"
        }]
      },
              {
                label: "Preamble", nodes: [
                  {
                    label: "image 4",
                    proxy: "v6huf"
                  },
                  {
                    label: "image 5",
                    proxy: "x3mmf"
                  }
                ]
              }]
    }
  end
  let(:flat_structure) do
    {
      nodes: [
        { proxy: "s45u4", label: "vol 1 front cover" },
        { proxy: "x04jf", label: "vol 1 pastedown" },
        { proxy: "iocby", label: "vol 1 front flyleaf 1" },
        { proxy: "jiots", label: "vol 1 front flyleaf 1v" }
      ]
    }
  end

  describe "identifiers" do
    subject(:mets_document) { described_class.new mets_file }

    context "with a UUID identifier" do
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0036-135-01.mets") }
      it "doesn't have an ark id" do
        expect(mets_document.ark_id).to be_blank
      end
    end

    it "has an ark id" do
      expect(mets_document.ark_id).to eq("ark:/88435/5m60qr98htest")
    end

    it "has a bib id" do
      expect(mets_document.bib_id).to eq("4612596")
    end

    it "has a pudl id" do
      expect(mets_document.pudl_id).to eq("pudl0001/4612596")
    end

    it "has a collection slug" do
      expect(mets_document.collection_slug).to eq("pudl0001")
    end
  end

  describe "files" do
    subject(:mets_document) { described_class.new mets_file_rtl }

    it "has a thumbnail url" do
      expect(mets_document.thumbnail_path).to eq("/tmp/pudl0032/ns73/00000001.tif")
    end

    it "has an array of files" do
      expect(mets_document.files.length).to eq(189)
      file = mets_document.files.first
      expect(file[:checksum]).to eq("aa2c70843bbd652b0a8ba426b7bc9211c547f9de")
      expect(file[:mime_type]).to eq("image/tiff")
      expect(file[:path]).to eq("/tmp/pudl0032/ns73/00000001.tif")
      expect(file[:replaces]).to eq("pudl0032/ns73/00000001")
    end

    it "has no options for files present in the structMap" do
      expect(mets_document.file_opts(mets_document.files.first)).to eq({})
    end

    it "has marks a file not present in the structMap as non-paged" do
      expect(mets_document.file_opts(mets_document.files.last)).to eq(viewing_hint: "non-paged")
    end

    it "finds labels for files" do
      expect(mets_document.file_label("gjpt0")).to eq("Upper cover. outside")
    end
  end

  describe "viewing direction" do
    context "a left-to-right object" do
      subject(:mets_document) { described_class.new mets_file }

      it "is right-to-left" do
        expect(mets_document.right_to_left).to be false
      end
      it "has a right-to-left viewing direction" do
        expect(mets_document.viewing_direction).to eq("left-to-right")
      end
    end

    context "a right-to-left object" do
      subject(:mets_document) { described_class.new mets_file_rtl }

      it "is right-to-left" do
        expect(mets_document.right_to_left).to be true
      end
      it "has a right-to-left viewing direction" do
        expect(mets_document.viewing_direction).to eq("right-to-left")
      end
    end
  end

  describe "viewing hint" do
    context "by default" do
      subject(:mets_document) { described_class.new mets_file }

      it "is paged" do
        expect(mets_document.viewing_hint).to eq("paged")
      end
    end

    context "for tight bound manuscripts" do
      subject(:mets_document) { described_class.new tight_bound_mets_file }

      it "is blank" do
        expect(mets_document.viewing_hint).to eq nil
      end
    end
  end

  describe "multi-volume" do
    context "a single-volume mets file" do
      subject(:mets_document) { described_class.new mets_file }

      it "is not multi-volume" do
        expect(mets_document.multi_volume?).to be false
      end

      it "has no volume ids" do
        expect(mets_document.volume_ids).to eq []
      end
    end

    context "a multi-volume mets file" do
      subject(:mets_document) { described_class.new mets_file_multi }

      it "is multi-volume" do
        expect(mets_document.multi_volume?).to be true
      end

      it "has volume ids" do
        expect(mets_document.volume_ids).to eq ["phys1", "phys2"]
      end

      it "has volume labels" do
        expect(mets_document.label_for_volume("phys1")).to eq "first volume"
      end

      it "has volume file lists" do
        expect(mets_document.files_for_volume("phys1").length).to eq 3
      end

      it "builds a label for a file from hierarchy (but does not include volume label)" do
        expect(mets_document.file_label("l898s")).to eq("upper cover. pastedown")
      end

      it "includes volume labels in replaces string" do
        expect(mets_document.files_for_volume("phys1").first[:replaces]).to eq "pudl0001/9946093213506421/s42/phys1/00000001"
      end
    end

    context "an item with logical structure" do
      subject(:mets_document) { described_class.new mets_file_rtl }
      it "has structure" do
        expect(mets_document.structure).to eq structure
      end
    end

    context "a multi-volume item with logical structure" do
      subject(:mets_document) { described_class.new mets_file_multi2 }

      it "uses the logical structure" do
        expect(mets_document.volume_ids).to eq ["v1log", "v2log", "v3log", "v4log", "v5log", "v6log", "v7log"]
      end
    end

    context "a multi-volume item with sections that begin and end in the middle of a page" do
      subject(:mets_document) { described_class.new mets_file_multi3 }

      it "does not duplicate pages" do
        expect(mets_document.volume_ids).to eq ["v1log"]
        expect(mets_document.files_for_volume("v1log").length).to eq 3
      end
    end

    context "a multi-volume item with smLink references to volume structure" do
      subject(:mets_document) { described_class.new mets_file_multi4 }
      let(:expected_structure) do
        {
          "nodes":
          [
            {
              "label": "front cover", "proxy": "nrwkc"
            },
            {
              "label": "front paste down", "proxy": "fh2bx"
            },
            {
              "label": "[Frontispice]", "nodes":
              [
                {
                  "label": "frontispice", "proxy": "jtatf"
                },
                {
                  "label": "frontispice 1v", "proxy": "dj7kh"
                }
              ]
            },
            {
              "label": "[Title Page]", "nodes":
              [
                {
                  "label": "p. 1", "proxy": "v7j0i"
                },
                {
                  "label": "p. 2", "proxy": "nqks4"
                }
              ]
            },
            {
              "label": "Premier Cahier", "nodes":
              [
                {
                  "label": "p. 5", "proxy": "hsf26"
                },
                {
                  "label": "p. 6", "proxy": "mkqpy"
                },
                {
                  "label": "Pavillon d'agrément, gothique anglais, Londres, par Jean Grunden. Pl. 1 et 2",
                  "nodes":
                  [
                    {
                      "label": "plate 1", "proxy": "ejgtg"
                    },
                    {
                      "label": "plate 1v", "proxy": "z3g5g"
                    }
                  ]
                }
              ]
            }
          ]
        }
      end

      it "uses the logical structure" do
        expect(mets_document.volume_ids).to eq ["v1phys", "v2phys"]
        expect(mets_document.structure_for_volume("v1phys")).to eq expected_structure
      end
    end

    context "an item with no logical structmap" do
      subject(:mets_document) { described_class.new no_logical_order_mets_file }

      it "defaults to the RelatedObjects order" do
        expect(mets_document.structure).to eq flat_structure
      end
    end
  end

  describe "pudl0017" do
    context "when given a mods file" do
      subject(:mets_document) { described_class.new(mets_file) }
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0017-wc064-s-s2687.mets") }
      it "can get the MODS metadata" do
        expect(mets_document.attributes).not_to be_blank
        expect(mets_document.attributes[:series]).to eq ["American views"]
      end
    end
  end
  describe "pudl0038" do
    context "when given a mods file" do
      subject(:mets_document) { described_class.new(mets_file) }
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0038-mp090-0894.mets") }
      it "can get the MODS metadata" do
        stub_ezid(shoulder: "88435", blade: "ww72bb49w", location: "http://findingaids.princeton.edu/collections/AC111")
        expect(mets_document.attributes).not_to be_blank
        expect(mets_document.attributes[:title].first).to be_a TitleWithSubtitle
        expect(mets_document.attributes[:coverage_point].first).to be_a CoveragePoint
      end
    end
  end
  describe "#pudl0100" do
    context "when given a mods file without a holding location" do
      subject(:mets_document) { described_class.new(mets_file) }
      let(:mets_file) { Rails.root.join("spec", "fixtures", "mets", "pudl0100-lc-egx_0003-nolocation.mets") }
      it "can get the MODS metadata" do
        expect(mets_document.attributes[:holding_location]).to be_blank
      end
    end
  end
end
