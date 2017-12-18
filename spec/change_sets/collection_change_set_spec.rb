# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CollectionChangeSet do
  subject(:change_set) { described_class.new(collection) }
  let(:collection) { FactoryBot.build(:collection) }
  before do
    change_set.prepopulate!
  end
  describe "#title" do
    it "is single-valued and required" do
      expect(change_set.multiple?(:title)).to eq false
      expect(change_set.required?(:title)).to eq true
      expect(change_set.validate(title: "")).to eq false
    end
  end

  describe "#slug" do
    it "is single-valued and required" do
      expect(change_set.multiple?(:slug)).to eq false
      expect(change_set.required?(:slug)).to eq true
      expect(change_set.validate(slug: "")).to eq false
    end
  end

  describe "#description" do
    it "is single-valued and not required" do
      expect(change_set.multiple?(:description)).to eq false
      expect(change_set.required?(:description)).to eq false
    end
  end

  describe "#visibility" do
    it "is single-valued and not required" do
      expect(change_set.multiple?(:description)).to eq false
      expect(change_set.required?(:description)).to eq false
    end
  end

  describe "#primary_terms" do
    it "returns the primary terms" do
      expect(change_set.primary_terms).to eq [:title, :slug, :description]
    end
  end
end
