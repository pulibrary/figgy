# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "a ChangeSet with EmbargoDate" do
  before do
    raise "change_set must be set with `let(:change_set)`" unless
      defined? change_set
    raise "resource_klass must be set with `let(:resource_klass)`" unless
      defined? resource_klass
  end

  describe "#embargo_date" do
    let(:form_resource) { resource_klass.new(embargo_date: "1/13/2023") }

    it "provides a string for the form to use" do
      expect(change_set.embargo_date).to eq "1/13/2023"
    end
  end
end
