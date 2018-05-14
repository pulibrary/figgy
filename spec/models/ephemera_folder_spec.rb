# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe EphemeraFolder do
  subject(:folder) { described_class.new(title: "test title") }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(folder.title).to include "test title"
  end
  context "with a title in a non-Latin orthographies" do
    subject(:folder) { described_class.new(title: title, transliterated_title: transliterated_title) }
    let(:title) { "Что делать?" }
    let(:transliterated_title) { 'Chto delat\'?' }
    it "has a non-Latin title and a transliterated Latin title" do
      expect(folder.title).to include title
      expect(folder.transliterated_title).to include transliterated_title
    end
  end
  it "has ordered member_ids" do
    folder.member_ids = [1, 2, 3, 3]
    expect(folder.member_ids).to eq [1, 2, 3, 3]
  end
  it "can have manifests" do
    expect(folder.class.can_have_manifests?).to be true
  end
  it "can have a date range" do
    folder.date_range = DateRange.new(start: "2017", end: "2018")
    expect(folder.date_range.first.start).to eq ["2017"]
  end
  it "has provenance attribute" do
    folder.provenance = ["Donated by The Mario Bros"]
    expect(folder.provenance.first).to eq "Donated by The Mario Bros"
  end
end
