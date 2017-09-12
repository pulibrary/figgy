# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraBoxDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_box) }
  describe "decoration" do
    it "decorates an EphemeraBox" do
      expect(resource.decorate).to be_a described_class
    end
  end
  it 'does not manage files' do
    expect(decorator.manageable_files?).to be false
  end
  it 'does not manage structures' do
    expect(decorator.manageable_structure?).to be false
  end
end
