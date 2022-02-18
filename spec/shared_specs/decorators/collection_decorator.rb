# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a CollectionDecorator" do
  before do
    raise "collection must be set with `let(:collection)`" unless
      defined? collection
    raise "decorator must be set with `let(:decorator)`" unless
      defined? decorator
  end

  it "has no files which can be managed" do
    expect(decorator.manageable_files?).to be false
  end

  describe "#collections" do
    it "cannot have parent collections" do
      expect(decorator.collections).to be_empty
    end
  end

  describe "#parents" do
    it "cannot have parent resources" do
      expect(decorator.parents).to be_empty
    end
  end
end
