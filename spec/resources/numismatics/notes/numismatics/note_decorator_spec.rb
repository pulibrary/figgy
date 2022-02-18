# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::NoteDecorator do
  subject(:decorator) { described_class.new(note) }
  let(:note) { Numismatics::Note.new(note: "also attributed to Andronicus III", type: "attribution") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    it "renders the note title" do
      expect(decorator.title).to eq("also attributed to Andronicus III")
    end
  end
end
