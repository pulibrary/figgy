# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::FindDecorator do
  subject(:decorator) { described_class.new(find) }
  let(:find) { FactoryBot.create_for_repository(:numismatic_find) }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be true
      expect(decorator.manageable_structure?).to be false
    end
  end
end
