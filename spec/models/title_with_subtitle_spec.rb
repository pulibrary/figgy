# frozen_string_literal: true

require "rails_helper"

RSpec.describe TitleWithSubtitle do
  describe "title" do
    it "reads / writes RDF::Literals and strings" do
      title_with_subtitle = described_class.new(title: RDF::Literal.new("Hello world", language: "eng"), subtitle: "I am a computer")
      expect(title_with_subtitle.to_s).to eq "Hello world: I am a computer"
    end
  end

  describe "#to_s" do
    it "combines title and subtitle" do
      title_with_subtitle = described_class.new(title: "Hello world", subtitle: "I am a computer")
      expect(title_with_subtitle.to_s).to eq "Hello world: I am a computer"
    end
  end
end
