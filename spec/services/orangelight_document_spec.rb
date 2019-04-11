# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

describe OrangelightDocument do
  describe "#to_json" do
    context "when a resource does not have an associated builder class" do
      subject(:builder) { described_class.new(scanned_resource) }
      let(:scanned_resource) { ScannedResource.new }

      it "raises a NotImplementedError" do
        expect { builder.to_json }.to raise_error(NotImplementedError)
      end
    end

    context "with an issue and a child coin" do
      subject(:builder) { described_class.new(coin) }
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
      let(:numismatic_artist) { NumismaticArtist.new(person: "artist person", signature: "artist signature", role: "artist role", side: "artist side") }
      let(:numismatic_citation) { NumismaticCitation.new(part: "citation part", number: "citation number", numismatic_reference_id: reference.id) }
      let(:artist) { FactoryBot.create_for_repository(:numismatic_artist) }
      let(:date_range) { DateRange.new(start: "-91", end: "-41", approximate: true) }
      let(:numismatic_place) { FactoryBot.create_for_repository(:numismatic_place) }
      let(:coin) do
        FactoryBot.create_for_repository(:coin,
                                         files: [file],
                                         holding_location: "Firestone",
                                         counter_stamp: "two small counter-stamps visible as small circles on reverse, without known parallel",
                                         analysis: "holed at 12 o'clock, 16.73 grams",
                                         public_note: ["Abraham Usher| John Field| Charles Meredith.", "Black and red ink.", "Visible flecks of mica."],
                                         private_note: ["was in the same case as coin #8822"],
                                         find_place: "Antioch, Syria",
                                         find_date: "5/27/1939?",
                                         find_feature: "Hill A?",
                                         find_locus: "8-N 40",
                                         find_number: "2237",
                                         find_description: "at join of carcares and w. cavea surface",
                                         die_axis: "6",
                                         size: "27",
                                         technique: "Cast",
                                         weight: "8.26")
      end
      let(:issue) do
        FactoryBot.create_for_repository(:numismatic_issue,
                                         member_ids: [coin.id],
                                         object_type: "coin",
                                         numismatic_artist: numismatic_artist,
                                         numismatic_citation: numismatic_citation,
                                         numismatic_place_id: numismatic_place.id,
                                         date_range: date_range,
                                         denomination: "1/2 Penny",
                                         metal: "copper",
                                         shape: "round",
                                         color: "green",
                                         edge: "GOTT MIT UNS",
                                         era: "uncertain",
                                         ruler: "George I",
                                         master: "William Wood",
                                         workshop: "Bristol",
                                         series: "Hibernia",
                                         obverse_figure: "bust",
                                         obverse_symbol: "cornucopia",
                                         obverse_part: "standing",
                                         obverse_orientation: "right",
                                         obverse_figure_description: "Harp at left side, 5 strings.",
                                         obverse_figure_relationship: "Victory behind",
                                         obverse_legend: "GEORGIUS•DEI•GRATIA•REX•",
                                         obverse_attributes: ["to left and right", "around edge"],
                                         reverse_figure: "Hibernia",
                                         reverse_symbol: "goat head",
                                         reverse_part: "seated",
                                         reverse_orientation: "left",
                                         reverse_figure_description: "Harp at right side, 11 strings. Right arm holding up a palm-branch",
                                         reverse_figure_relationship: "corn-ear behind head",
                                         reverse_legend: "•HIBERNIA•1723•",
                                         reverse_attributes: ["above", "2 within Є"],
                                         subject: ["unicorn"])
      end

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        coin
        issue
      end

      it "returns an Orangelight document" do
        output = MultiJson.load(builder.to_json, symbolize_keys: true)
        holding = JSON.parse(output[:holdings_1display]).first.last
        expect(output[:id]).to eq coin.decorate.orangelight_id
        expect(output[:title_display]).to eq "Coin: #{coin.coin_number}"
        expect(output[:pub_created_display]).to eq "George I, 1/2 Penny, city"
        expect(output[:call_number_display]).to eq ["Coin #{coin.coin_number}"]
        expect(output[:call_number_browse_s]).to eq ["Coin #{coin.coin_number}"]
        expect(output[:access_facet]).to eq ["Online", "In the Library"]
        expect(output[:location]).to eq ["Rare Books and Special Collections"]
        expect(output[:location_display]).to eq ["Rare Books and Special Collections - Numismatics Collection"]
        expect(output[:format]).to eq ["Coin"]
        expect(output[:advanced_location_s]).to eq ["num"]
        expect(output[:location_code_s]).to eq ["num"]
        expect(holding["call_number"]).to eq "Coin #{coin.coin_number}"
        expect(holding["call_number_browse"]).to eq "Coin #{coin.coin_number}"
        expect(holding["location_code"]).to eq "num"
        expect(holding["location"]).to eq "Rare Books and Special Collections - Numismatics Collection"
        expect(holding["library"]).to eq "Rare Books and Special Collections"
        expect(output[:counter_stamp_s]).to eq ["two small counter-stamps visible as small circles on reverse, without known parallel"]
        expect(output[:analysis_s]).to eq ["holed at 12 o'clock, 16.73 grams"]
        expect(output[:notes_display]).to eq ["Abraham Usher| John Field| Charles Meredith.", "Black and red ink.", "Visible flecks of mica."]
        expect(output[:find_place_s]).to eq ["Antioch, Syria"]
        expect(output[:find_date_s]).to eq ["5/27/1939?"]
        expect(output[:find_feature_s]).to eq ["Hill A?"]
        expect(output[:find_locus_s]).to eq ["8-N 40"]
        expect(output[:find_number_s]).to eq ["2237"]
        expect(output[:find_description_s]).to eq ["at join of carcares and w. cavea surface"]
        expect(output[:die_axis_s]).to eq ["6"]
        expect(output[:size_s]).to eq ["27"]
        expect(output[:technique_s]).to eq ["Cast"]
        expect(output[:weight_s]).to eq ["8.26"]
        expect(output[:pub_date_start_sort]).to eq(-91)
        expect(output[:pub_date_end_sort]).to eq(-41)
        expect(output[:issue_object_type_s]).to eq ["coin"]
        expect(output[:issue_denomination_s]).to eq ["1/2 Penny"]
        expect(output[:issue_denomination_sort]).to eq "1/2 Penny"
        expect(output[:issue_number_s]).to eq "1"
        expect(output[:issue_metal_s]).to eq ["copper"]
        expect(output[:issue_metal_sort]).to eq "copper"
        expect(output[:issue_shape_s]).to eq ["round"]
        expect(output[:issue_color_s]).to eq ["green"]
        expect(output[:issue_edge_s]).to eq ["GOTT MIT UNS"]
        expect(output[:issue_era_s]).to eq ["uncertain"]
        expect(output[:issue_ruler_s]).to eq ["George I"]
        expect(output[:issue_ruler_sort]).to eq "George I"
        expect(output[:issue_master_s]).to eq ["William Wood"]
        expect(output[:issue_workshop_s]).to eq ["Bristol"]
        expect(output[:issue_series_s]).to eq ["Hibernia"]
        expect(output[:issue_place_s]).to eq ["city, state, region"]
        expect(output[:issue_place_sort]).to eq "city, state, region"
        expect(output[:issue_obverse_figure_s]).to eq ["bust"]
        expect(output[:issue_obverse_symbol_s]).to eq ["cornucopia"]
        expect(output[:issue_obverse_part_s]).to eq ["standing"]
        expect(output[:issue_obverse_orientation_s]).to eq ["right"]
        expect(output[:issue_obverse_figure_description_s]).to eq ["Harp at left side, 5 strings."]
        expect(output[:issue_obverse_figure_relationship_s]).to eq ["Victory behind"]
        expect(output[:issue_obverse_legend_s]).to eq ["GEORGIUS•DEI•GRATIA•REX•"]
        expect(output[:issue_obverse_attributes_s]).to eq ["to left and right", "around edge"]
        expect(output[:issue_reverse_figure_s]).to eq ["Hibernia"]
        expect(output[:issue_reverse_symbol_s]).to eq ["goat head"]
        expect(output[:issue_reverse_part_s]).to eq ["seated"]
        expect(output[:issue_reverse_orientation_s]).to eq ["left"]
        expect(output[:issue_reverse_figure_description_s]).to eq ["Harp at right side, 11 strings. Right arm holding up a palm-branch"]
        expect(output[:issue_reverse_figure_relationship_s]).to eq ["corn-ear behind head"]
        expect(output[:issue_reverse_legend_s]).to eq ["•HIBERNIA•1723•"]
        expect(output[:issue_reverse_attributes_s]).to eq ["above", "2 within Є"]
        expect(output[:issue_references_s]).to eq ["short-title citation part citation number"]
        expect(output[:issue_references_sort]).to eq "short-title citation part citation number"
        expect(output[:issue_artists_s]).to eq ["artist person, artist role"]
        expect(output[:issue_artists_sort]).to eq "artist person, artist role"
      end
    end

    context "with a coin not attached to an issue" do
      subject(:builder) { described_class.new(coin) }
      let(:coin) do
        FactoryBot.create_for_repository(:coin,
                                         holding_location: "Firestone",
                                         counter_stamp: "two small counter-stamps visible as small circles on reverse, without known parallel",
                                         analysis: "holed at 12 o'clock, 16.73 grams",
                                         public_note: ["Abraham Usher| John Field| Charles Meredith.", "Black and red ink.", "Visible flecks of mica."],
                                         private_note: ["was in the same case as coin #8822"],
                                         find_place: "Antioch, Syria",
                                         find_date: "5/27/1939?",
                                         find_feature: "Hill A?",
                                         find_locus: "8-N 40",
                                         find_number: "2237",
                                         find_description: "at join of carcares and w. cavea surface",
                                         die_axis: "6",
                                         size: "27",
                                         technique: "Cast",
                                         weight: "8.26")
      end

      it "will display an error" do
        expect(builder.to_h[:error]).to eq("#{coin.title.first} with id: #{coin.id} has no parent numismatic issue and cannot build an OL document.")
      end
    end
  end
end
