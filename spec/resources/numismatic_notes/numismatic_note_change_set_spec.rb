# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticNoteChangeSet do
  subject(:change_set) { described_class.new(note) }
  let(:note) { NumismaticNote.new }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:note, :type)
    end
  end
end
