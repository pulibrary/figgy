# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grouping do
  let(:title_with_subtitle) { TitleWithSubtitle.new(title: RDF::Literal.new("Hello world", language: "eng"), subtitle: "I am a computer") }
  let(:grouping) { described_class.new(elements: [title_with_subtitle, "Hi I am also a computer"]) }

  describe "elements" do
    it "reads/writes an array of various types" do
      expect(grouping.elements).to contain_exactly title_with_subtitle, "Hi I am also a computer"
    end
  end

  describe "to_s" do
    it "joins all the titles with semicolon" do
      expect(grouping.to_s).to eq "Hello world: I am a computer; Hi I am also a computer"
    end
  end
end
