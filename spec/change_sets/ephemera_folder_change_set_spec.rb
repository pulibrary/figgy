# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFolderChangeSet do
  subject(:change_set) { described_class.new(FactoryGirl.build(:ephemera_folder)) }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }

  describe "#visibility" do
    it "exposes the visibility" do
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "can update the visibility" do
      change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  describe "#state" do
    it "pre-populates" do
      change_set.prepopulate!
      expect(change_set.state).to eq "needs_qa"
    end
  end

  describe "#provenance" do
    it "pre-populates as single-value" do
      change_set.prepopulate!
      expect(change_set.provenance).to eq FactoryGirl.build(:ephemera_folder).provenance.first
    end
  end

  describe "#date_range" do
    it "can set it" do
      change_set.prepopulate!
      change_set.validate(date_range_form_attributes: { start: "2017", end: "2018" })
      change_set.sync
      expect(change_set.model.date_range.first.start).to eq ["2017"]
    end
    it "validates" do
      change_set.prepopulate!
      result = change_set.validate(date_range_form_attributes: { start: "abcd", end: "2018" })
      expect(result).to eq false
    end
    it "validates that the start is before the end" do
      change_set.prepopulate!
      result = change_set.validate(date_range_form_attributes: { start: "2018", end: "2017" })
      expect(result).to eq false
    end
    it "is invalid if only start is given" do
      change_set.prepopulate!
      result = change_set.validate(date_range_form_attributes: { start: "2018", end: "" })
      expect(result).to eq false
    end
    it "is invalid if only end is given" do
      change_set.prepopulate!
      result = change_set.validate(date_range_form_attributes: { start: "", end: "2018" })
      expect(result).to eq false
    end
    it "has a default" do
      change_set.prepopulate!
      expect(change_set.date_range_form.start).to be_nil
      expect(change_set.date_range_form.required?(:start)).to eq false
    end
    context "when there's a date range set" do
      it "sets it single-valued appropriately" do
        change_set = described_class.new(FactoryGirl.build(:ephemera_folder, date_range: DateRange.new(start: "2017", end: "2018")))
        change_set.prepopulate!
        expect(change_set.date_range_form.start).to eq "2017"
      end
    end
  end

  context 'with controlled vocabulary terms' do
    subject(:change_set) do
      described_class.new(FactoryGirl.build(:ephemera_folder))
    end

    let(:term1) do
      res = FactoryGirl.create_for_repository(:ephemera_term)
      adapter.persister.save(resource: res)
    end
    let(:term2) do
      res = FactoryGirl.create_for_repository(:ephemera_term)
      adapter.persister.save(resource: res)
    end
    let(:term3) do
      res = FactoryGirl.create_for_repository(:ephemera_term)
      adapter.persister.save(resource: res)
    end

    before do
      change_set.geo_subject = [term1.id]
      change_set.geographic_origin = term2.id
      change_set.subject = [term3.id]
    end

    it 'persists geo. subject values as IDs for controlled terms' do
      expect(change_set.geo_subject).not_to be_empty
      expect(change_set.geo_subject.first).to be_a Valkyrie::ID
    end

    it 'persists geographic origin values as IDs for controlled terms' do
      expect(change_set.geographic_origin).not_to be nil
      expect(change_set.geographic_origin).to be_a Valkyrie::ID
    end

    it 'persists subject as IDs for controlled terms' do
      expect(change_set.subject).not_to be_empty
      expect(change_set.subject.first).to be_a Valkyrie::ID
    end

    context 'with controlled vocabulary terms IDs as strings' do
      before do
        change_set.geo_subject = [term1.id.to_s]
        change_set.geographic_origin = term2.id.to_s
        change_set.subject = [term3.id.to_s]
      end

      it 'persists geo. subject values as IDs for controlled terms' do
        expect(change_set.geo_subject).not_to be_empty
        expect(change_set.geo_subject.first).to be_a Valkyrie::ID
      end

      it 'persists geographic origin values as IDs for controlled terms' do
        expect(change_set.geographic_origin).not_to be nil
        expect(change_set.geographic_origin).to be_a Valkyrie::ID
      end

      it 'persists subject as IDs for controlled terms' do
        expect(change_set.subject).not_to be_empty
        expect(change_set.subject.first).to be_a Valkyrie::ID
      end
    end
  end

  context 'without controlled vocabulary terms' do
    it 'does not coerce geo. subject values into IDs' do
      expect(change_set.geo_subject).to be_empty
    end

    it 'does not coerce geographic origin values into IDs' do
      expect(change_set.geographic_origin).to be nil
    end

    it 'does not coerce subject values into IDs' do
      expect(change_set.subject).to be_empty
    end
  end
end
