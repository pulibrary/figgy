# frozen_string_literal: true

require "rails_helper"

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
      let(:reference_coin) { FactoryBot.create_for_repository(:numismatic_reference, title: "Coin Test Reference", short_title: "Coin short-title") }
      let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
      let(:numismatic_artist) { Numismatics::Artist.new(person_id: person.id, signature: "artist signature", role: "artist role", side: "artist side") }
      let(:numismatic_subject) { Numismatics::Subject.new(type: "Other Person", subject: "Athena") }
      let(:numismatic_attribute) { Numismatics::Attribute.new(description: "attribute description", name: "attribute name") }
      let(:numismatic_citation) { Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: reference.id) }
      let(:numismatic_monogram1) { FactoryBot.create_for_repository(:numismatic_monogram, title: "Alexander", thumbnail_id: "alexander-url") }
      let(:numismatic_monogram2) { FactoryBot.create_for_repository(:numismatic_monogram, title: "Zeus", thumbnail_id: "zeus-url") }
      let(:artist) { FactoryBot.create_for_repository(:numismatic_artist) }
      let(:numismatic_accession) { FactoryBot.create_for_repository(:numismatic_accession, date: "1939-01-01T00:00:00.000Z", person_id: person.id) }
      let(:numismatic_place) { FactoryBot.create_for_repository(:numismatic_place) }
      let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
      let(:numismatic_provenance) { Numismatics::Provenance.new(person_id: person.id, note: "note", date: "12/04/1999") }
      let(:coin) do
        FactoryBot.create_for_repository(:coin,
          files: [file],
          counter_stamp: "two small counter-stamps visible as small circles on reverse, without known parallel",
          analysis: "holed at 12 o'clock, 16.73 grams",
          public_note: ["identification uncertain"],
          private_note: ["was in the same case as coin #8822"],
          find_place_id: numismatic_place.id,
          find_date: "5/27/1939?",
          find_feature: "Hill A?",
          find_locus: "8-N 40",
          find_number: "2237",
          find_description: "at join of carcares and w. cavea surface",
          numismatic_accession_id: numismatic_accession.id,
          numismatic_collection: "Firestone",
          numismatic_citation: numismatic_citation,
          provenance: numismatic_provenance,
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
          numismatic_subject: numismatic_subject,
          numismatic_place_id: numismatic_place.id,
          obverse_attribute: numismatic_attribute,
          reverse_attribute: numismatic_attribute,
          ruler_id: numismatic_person.id,
          master_id: numismatic_person.id,
          earliest_date: "-91",
          latest_date: "-41",
          numismatic_monogram_ids: [numismatic_monogram1.id, numismatic_monogram2.id],
          denomination: "1/2 Penny",
          metal: "copper",
          shape: "round",
          color: "green",
          edge: "GOTT MIT UNS",
          era: "uncertain",
          workshop: "Bristol",
          series: "Hibernia",
          obverse_figure: "bust",
          obverse_symbol: "cornucopia",
          obverse_part: "standing",
          obverse_orientation: "right",
          obverse_figure_description: "Harp at left side, 5 strings.",
          obverse_figure_relationship: "Victory behind",
          obverse_legend: "GEORGIUS•DEI•GRATIA•REX•",
          reverse_figure: "emperor and Virgin",
          reverse_symbol: "goat head",
          reverse_part: "seated",
          reverse_orientation: "left",
          reverse_figure_description: "Harp at right side, 11 strings. Right arm holding up a palm-branch",
          reverse_figure_relationship: "corn-ear behind head",
          reverse_legend: "•HIBERNIA•1723•")
      end

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        coin
        issue
      end

      it "returns an Orangelight document" do
        output = MultiJson.load(builder.to_json, symbolize_keys: true)
        holding = JSON.parse(output[:holdings_1display]).first.last

        # Fields to capitalize
        expect(output[:issue_metal_s]).to eq ["Copper"]
        expect(output[:issue_era_s]).to eq ["Uncertain"]
        expect(output[:issue_obverse_figure_s]).to eq ["Bust"]
        expect(output[:issue_reverse_figure_s]).to eq ["Emperor and Virgin"]
        expect(output[:analysis_s]).to eq ["Holed at 12 o'clock, 16.73 grams"]
        expect(output[:notes_display]).to eq ["Identification uncertain"]

        # All the rest of the fields
        expect(output[:id]).to eq coin.decorate.orangelight_id
        expect(output[:title_display]).to eq "Coin: #{coin.coin_number}"
        expect(output[:pub_created_display]).to eq "name1 name2 epithet (1868 to 1963), 1/2 Penny, city"
        expect(output[:call_number_display]).to eq ["Coin #{coin.coin_number}"]
        expect(output[:call_number_browse_s]).to eq ["Coin #{coin.coin_number}"]
        expect(output[:access_facet]).to eq ["Online", "In the Library"]
        expect(output[:location]).to eq ["Special Collections"]
        expect(output[:location_display]).to eq ["Special Collections - Numismatics Collection"]
        expect(output[:format]).to eq ["Coin"]
        expect(output[:advanced_location_s]).to eq ["rare$num"]
        expect(output[:location_code_s]).to eq ["rare$num"]
        expect(holding["call_number"]).to eq "Coin #{coin.coin_number}"
        expect(holding["call_number_browse"]).to eq "Coin #{coin.coin_number}"
        expect(holding["location_code"]).to eq "rare$num"
        expect(holding["location"]).to eq "Special Collections - Numismatics Collection"
        expect(holding["library"]).to eq "Special Collections"
        expect(output[:counter_stamp_s]).to eq ["two small counter-stamps visible as small circles on reverse, without known parallel"]
        expect(output[:find_place_s]).to eq ["city, state, region"]
        expect(output[:find_date_s]).to eq ["5/27/1939?"]
        expect(output[:find_feature_s]).to eq ["Hill A?"]
        expect(output[:find_locus_s]).to eq ["8-N 40"]
        expect(output[:find_number_s]).to eq ["2237"]
        expect(output[:find_description_s]).to eq ["at join of carcares and w. cavea surface"]
        expect(output[:die_axis_s]).to eq ["6"]
        expect(output[:size_s]).to eq ["27 in mm"]
        expect(output[:technique_s]).to eq ["Cast"]
        expect(output[:weight_s]).to eq ["8.26 in grams"]
        expect(output[:pub_date_start_sort]).to eq(-91)
        expect(output[:pub_date_end_sort]).to eq(-41)
        expect(output[:numismatic_collection_s]).to eq ["Firestone"]
        expect(output[:numismatic_accession_s]).to eq ["Accession number: 1, 1939-01-01, Gift of: name1 name2"]
        expect(output[:numismatic_provenance_s]).to eq ["name1 name2; 12/04/1999; note"]
        expect(output[:issue_object_type_s]).to eq ["coin"]
        expect(output[:issue_denomination_s]).to eq ["1/2 Penny"]
        expect(output[:issue_denomination_sort]).to eq "1/2 Penny"
        expect(output[:issue_number_s]).to eq "1"
        expect(output[:issue_metal_sort]).to eq "copper"
        expect(output[:issue_shape_s]).to eq ["round"]
        expect(output[:issue_color_s]).to eq ["green"]
        expect(output[:issue_edge_s]).to eq ["GOTT MIT UNS"]
        expect(output[:issue_ruler_s]).to eq ["name1 name2 epithet (1868 to 1963)"]
        expect(output[:issue_ruler_sort]).to eq "name1 name2 epithet (1868 to 1963)"
        expect(output[:issue_master_s]).to eq ["name1 name2 epithet (1868 to 1963)"]
        expect(output[:issue_workshop_s]).to eq ["Bristol"]
        expect(output[:issue_series_s]).to eq ["Hibernia"]
        expect(output[:issue_place_s]).to eq ["city, state, region"]
        expect(output[:issue_city_s]).to eq ["city"]
        expect(output[:issue_state_s]).to eq ["state"]
        expect(output[:issue_region_s]).to eq ["region"]
        expect(output[:issue_place_sort]).to eq "city, state, region"
        expect(output[:issue_obverse_symbol_s]).to eq ["cornucopia"]
        expect(output[:issue_obverse_description_s]).to eq "Bust, standing, right, Harp at left side, 5 strings."
        expect(output[:issue_obverse_part_s]).to eq ["standing"]
        expect(output[:issue_obverse_orientation_s]).to eq ["right"]
        expect(output[:issue_obverse_figure_description_s]).to eq ["Harp at left side, 5 strings."]
        expect(output[:issue_obverse_figure_relationship_s]).to eq ["Victory behind"]
        expect(output[:issue_obverse_legend_s]).to eq ["GEORGIUS•DEI•GRATIA•REX•"]
        expect(output[:issue_obverse_attributes_s]).to eq ["attribute name, attribute description"]
        expect(output[:issue_reverse_symbol_s]).to eq ["goat head"]
        expect(output[:issue_reverse_description_s]).to eq "Emperor and Virgin, seated, right, Harp at left side, 5 strings."
        expect(output[:issue_reverse_part_s]).to eq ["seated"]
        expect(output[:issue_reverse_orientation_s]).to eq ["left"]
        expect(output[:issue_reverse_figure_description_s]).to eq ["Harp at right side, 11 strings. Right arm holding up a palm-branch"]
        expect(output[:issue_reverse_figure_relationship_s]).to eq ["corn-ear behind head"]
        expect(output[:issue_reverse_legend_s]).to eq ["•HIBERNIA•1723•"]
        expect(output[:issue_reverse_attributes_s]).to eq ["attribute name, attribute description"]
        expect(output[:issue_references_s]).to eq ["short-title citation part citation number"]
        expect(output[:issue_references_sort]).to eq "short-title citation part citation number"
        expect(output[:issue_artists_s]).to eq ["name1 name2, artist signature"]
        expect(output[:issue_subjects_s]).to eq ["Other Person, Athena"]
        expect(output[:issue_artists_sort]).to eq "name1 name2, artist signature"
        expect(output[:issue_monogram_title_s]).to contain_exactly("Alexander", "Zeus")
        expect(output[:issue_date_s]).to eq ["-91 to -41"]
        expect(output[:coin_references_s]).to eq ["short-title citation part citation number"]
        expect(output[:coin_references_sort]).to eq "short-title citation part citation number"
      end
    end

    context "with a coin not attached to an issue" do
      subject(:builder) { described_class.new(coin) }
      let(:coin) { FactoryBot.create_for_repository(:coin) }

      it "will display an error" do
        expect { builder.to_h[:error] }.to raise_error(OrangelightCoinBuilder::NoParentException, /#{coin.title.first} with id: #{coin.id}/)
      end
    end
  end
end
