require "rails_helper"

RSpec.describe Webdav::TitleRange do
  describe ".root" do
    it "matches everything and splits into digits, letters, and scripts" do
      root = described_class.root
      expect(root.solr_filter).to be_nil
      names = root.children.map(&:name)
      expect(names).to include("0", "9", "a", "m", "z", "α–Я", "一–鿿")
      expect(names.first).to eq "%00–%2F"
    end
  end

  describe "#solr_filter" do
    it "covers a whole prefix, including the title equal to the prefix" do
      expect(described_class.parse("ma").solr_filter).to eq 'title_ssort:["ma" TO "mb"}'
    end

    it "covers a range of next characters" do
      expect(described_class.parse("ma–mf").solr_filter).to eq 'title_ssort:["ma" TO "mg"}'
    end

    it "escapes quotes and backslashes" do
      expect(described_class.new(prefix: %(a"\\), lo: 0, hi: described_class::MAX).solr_filter).to eq 'title_ssort:["a\\"\\\\" TO "a\\"]"}'
    end

    it "is open-ended at the top of the codepoint space" do
      expect(described_class.new(prefix: "", lo: 0xd7b0, hi: described_class::MAX).solr_filter).to eq 'title_ssort:["ힰ" TO *}'
    end
  end

  describe ".parse" do
    it "round trips every child name, including escaped characters" do
      ranges = described_class.root.children + described_class.parse("the").children + described_class.parse("ma–mz").children
      ranges.each do |range|
        parsed = described_class.parse(range.name)
        expect([parsed.prefix, parsed.lo, parsed.hi]).to eq [range.prefix, range.lo, range.hi]
      end
    end

    it "encodes characters that can't go in a folder name" do
      range = described_class.new(prefix: "a/b: c%", lo: 0, hi: described_class::MAX)
      expect(range.name).to eq "a%2Fb%3A%20c%25"
      expect(described_class.parse(range.name).prefix).to eq "a/b: c%"
    end

    it "rejects malformed names" do
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse("a–")).to be_nil
      expect(described_class.parse("ab–c")).to be_nil
      expect(described_class.parse("ab–ac–ad")).to be_nil
      expect(described_class.parse("af–aa")).to be_nil
      expect(described_class.parse("%FF")).to be_nil
    end
  end

  describe "#children" do
    it "bisects a range into ordered, contiguous pieces at characters folding won't move" do
      range = described_class.parse("m{–mΰ")
      children = range.children
      expect(children.size).to be <= described_class::BISECT_WAYS
      expect(children.first.lo).to eq range.lo
      children.each_cons(2) { |a, b| expect(a.hi).to eq b.lo }
      boundaries = children.map(&:lo).drop(1).map { |cp| cp.chr(Encoding::UTF_8) }
      boundaries.each do |char|
        expect(char.unicode_normalize(:nfkd)).to eq char
        expect(char.downcase(:fold)).to eq char
      end
    end

    it "never uses surrogate codepoints" do
      range = described_class.new(prefix: "", lo: 0xd000, hi: 0xe100)
      expect(range.children.flat_map { |c| [c.lo, c.hi] }).to all(satisfy { |cp| !cp.between?(0xd800, 0xdfff) })
    end
  end
end
