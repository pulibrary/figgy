# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaBagParser do
  let(:bag_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
  let(:amb_parser) { described_class.new(path: bag_path, component_id: "C0652") }

  before do
    stub_pulfa(pulfa_id: "C0652")
  end

  describe "#file_groups" do
    it { expect(amb_parser.file_groups.keys).to contain_exactly "32101047382401_2", "32101047382401_1" }
    it { expect(amb_parser.file_groups["32101047382401_2"].map(&:original_filename).map(&:to_s)).to contain_exactly "32101047382401_2_a.mp3", "32101047382401_2_i.wav", "32101047382401_2_pm.wav" }
  end

  describe "#component_groups" do
    it { expect(amb_parser.component_groups.keys).to contain_exactly "C0652_c0377" }
  end
end
