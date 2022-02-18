# frozen_string_literal: true

require "rails_helper"

RSpec.describe DateRangeProperty do
  subject(:change_set) { TestChangeSet.new(resource) }
  before(:all) do
    class TestChangeSet < ChangeSet
      include DateRangeProperty
    end

    class TestResource < Resource
      attribute :date_range
    end
  end
  after(:all) do
    Object.send(:remove_const, :TestChangeSet)
  end

  let(:resource) { TestResource.new }

  it "can set date_range" do
    change_set.validate(date_range_form_attributes: {start: "2017", end: "2018"})
    change_set.sync
    expect(change_set.model.date_range.first.end).to eq ["2018"]
    expect(change_set.model.date_range.first.start).to eq ["2017"]
    expect(change_set.model.date_range.first.approximate).to be nil
  end

  it "can set approximate date_range" do
    change_set.validate(date_range_form_attributes: {start: "2017", end: "2018", approximate: true})
    change_set.sync
    expect(change_set.model.date_range.first.start).to eq ["2017"]
    expect(change_set.model.date_range.first.end).to eq ["2018"]
    expect(change_set.model.date_range.first.approximate).to be true
  end

  it "validates" do
    result = change_set.validate(date_range_form_attributes: {start: "abcd", end: "2018"})
    expect(result).to eq false
  end

  it "validates that the start is before the end" do
    result = change_set.validate(date_range_form_attributes: {start: "2018", end: "2017"})
    expect(result).to eq false
  end

  it "is invalid if only start is given" do
    result = change_set.validate(date_range_form_attributes: {start: "2018", end: ""})
    expect(result).to eq false
  end

  it "is invalid if only end is given" do
    result = change_set.validate(date_range_form_attributes: {start: "", end: "2018"})
    expect(result).to eq false
  end

  it "has a default" do
    change_set.prepopulate!
    expect(change_set.date_range_form.start).to be_nil
    expect(change_set.date_range_form.required?(:start)).to eq false
  end

  context "when there's a date range set" do
    let(:resource) { FactoryBot.build(:scanned_resource, date_range: DateRange.new(start: "2017", end: "2018")) }
    it "sets it single-valued appropriately" do
      change_set.prepopulate!
      expect(change_set.date_range_form.start).to eq "2017"
    end
  end
end
