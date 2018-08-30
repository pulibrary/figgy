# frozen_string_literal: true
require "rails_helper"

RSpec.describe Grouping do
  describe "elements" do
    it "reads/writes an array of various types" do
      title_with_subtitle = TitleWithSubtitle.new(title: RDF::Literal.new("Hello world", language: "eng"), subtitle: "I am a computer")
      grouping = described_class.new(elements: [title_with_subtitle, "Hi I am also a computer"])
      expect(grouping.elements).to contain_exactly title_with_subtitle, "Hi I am also a computer"
    end
  end
end
