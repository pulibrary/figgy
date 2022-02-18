# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProxyFileSetChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:proxy_file_set) { ProxyFileSet.new }
  let(:form_resource) { proxy_file_set }

  describe "#prepopulate!" do
    it "sets default private visibility" do
      expect(change_set.visibility).to eq visibility
    end
  end

  describe "validations" do
    context "label" do
      let(:proxy_file_set) { ProxyFileSet.new }
      it "is required" do
        change_set.validate(proxied_file_id: Valkyrie::ID.new("my_id"))
        expect(change_set).not_to be_valid
        change_set.validate(label: "Some Songs")
        expect(change_set).to be_valid
      end
    end

    context "proxied_file_id" do
      let(:proxy_file_set) { ProxyFileSet.new }
      it "is required" do
        change_set.validate(label: "Some Songs")
        expect(change_set).not_to be_valid
        change_set.validate(proxied_file_id: Valkyrie::ID.new("my_id"))
        expect(change_set).to be_valid
      end
    end
  end

  describe "#primary_terms" do
    it "contains label" do
      expect(change_set.primary_terms).to eq [:label]
    end
  end
end
