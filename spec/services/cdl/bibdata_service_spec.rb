# frozen_string_literal: true
require "rails_helper"

RSpec.describe Cdl::BibdataService do
  before do
    stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
      .to_return(status: 200,
                 body:
             {
               :f => [
                 {
                   :holding_id => 1_581_046,
                   :call_number => "NA203 .G5 1967",
                   :items => [
                     {
                       :id => 1_666_778,
                       :on_cdl => "N",
                       :on_reserve => "N",
                       :copy_number => 1,
                       :item_sequence_number => 1,
                       :temp_location => "null",
                       :perm_location => "f",
                       :circ_group_id => 1,
                       :pickup_location_code => "fcirc",
                       :pickup_location_id => 299,
                       :enum => "null",
                       :chron => "null",
                       :barcode => "32101003160700",
                       :item_type => "Gen",
                       :due_date => "null",
                       :status => [
                         "Not Charged"
                       ]
                     }
                   ],
                   :sortable_call_number => "NA.0203.G5.1967"
                 }
               ],
               :st => [
                 {
                   :holding_id => 1_581_047,
                   :call_number => "NA200 .G38 1967",
                   :items => [
                     {
                       :id => 1_666_779,
                       :on_cdl => "Y",
                       :on_reserve => "N",
                       :copy_number => 1,
                       :item_sequence_number => 1,
                       :temp_location => "null",
                       :perm_location => "st",
                       :circ_group_id => 14,
                       :pickup_location_code => "stcirc",
                       :pickup_location_id => 345,
                       :enum => "null",
                       :chron => "null",
                       :barcode => "32101015237520",
                       :item_type => "Gen",
                       :due_date => "null",
                       :status => [
                         "Not Charged"
                       ]
                     }
                   ]
                 }
               ],
               :uesrf => [
                 {
                   :holding_id => 1_581_050,
                   :call_number => "NA203 .G5 1967",
                   :items => [
                     {
                       :id => 1_666_782,
                       :on_cdl => "Y",
                       :on_reserve => "N",
                       :copy_number => 2,
                       :item_sequence_number => 1,
                       :temp_location => "null",
                       :perm_location => "uesrf",
                       :circ_group_id => 5,
                       :pickup_location_code => "uescirc",
                       :pickup_location_id => 356,
                       :enum => "null",
                       :chron => "null",
                       :barcode => "32101019151941",
                       :item_type => "NoCirc",
                       :due_date => "null",
                       :status => [
                         "Not Charged"
                       ]
                     }
                   ]
                 }
               ]
             }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end

  describe ".item_ids" do
    context "on_cdl is null" do
      before do
        stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
          .to_return(status: 200,
                     body: { :uesrf => [
                       {
                         :holding_id => 1_581_050,
                         :call_number => "NA203 .G5 1967",
                         :items => [
                           {
                             :id => 1_666_782,
                             :on_cdl => "null",
                             :on_reserve => "N",
                             :copy_number => 2,
                             :item_sequence_number => 1,
                             :temp_location => "null",
                             :perm_location => "uesrf",
                             :circ_group_id => 5,
                             :pickup_location_code => "uescirc",
                             :pickup_location_id => 356,
                             :enum => "null",
                             :chron => "null",
                             :barcode => "32101019151941",
                             :item_type => "NoCirc",
                             :due_date => "null",
                             :status => [
                               "Not Charged"
                             ]
                           }
                         ]
                       }
                     ] }.to_json, headers: {})
      end
      let(:bib_id) { "7214786" }

      it "will not error if the on_cdl is null" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
      end
    end

    context "querying a suppressed bib" do
      before do
        stub_request(:get, "https://bibdata.princeton.edu/#{bib_id}/items")
          .to_return(status: 404,
                     body: {}.to_json, headers: {})
      end
      let(:bib_id) { "11174664" }
      it "will not error" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq []
      end
    end

    context "a bib_id with items in more than one locations" do
      let(:bib_id) { "7214786" }
      it "returns only the cdl charged items" do
        expect(described_class.item_ids(source_metadata_identifier: bib_id)).to eq [1_666_779, 1_666_782]
      end
    end
  end
end
