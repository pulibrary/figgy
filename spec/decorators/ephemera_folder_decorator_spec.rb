# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraFolderDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_folder) }
  describe "decoration" do
    it "decorates an EphemeraFolder" do
      expect(resource.decorate).to be_a described_class
    end
  end
  describe "decoration" do
    it "decorates an EphemeraFolder" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'manages files' do
    expect(decorator.manageable_files?).to be true
  end
  it 'manages structures' do
    expect(decorator.manageable_structure?).to be true
  end
end
