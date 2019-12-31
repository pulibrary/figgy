# frozen_string_literal: true
require "rails_helper"

RSpec.shared_examples "an optimistic locking change set" do
  before do
    raise "change_set must be set with `let(:change_set)`" unless
      defined? change_set
  end

  describe "#optimistic_lock_token" do
    it "is a defined property" do
      expect(change_set.optimistic_lock_token).to be_a Array
    end

    it "is defined as a primary term" do
      if change_set.primary_terms.is_a? Array
        expect(change_set.primary_terms).to include :optimistic_lock_token
      elsif change_set.primary_terms.is_a? Hash
        expect(change_set.primary_terms[""]).to include :optimistic_lock_token
      end
    end
  end
end
