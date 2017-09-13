# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraTemplateDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryGirl.build(:ephemera_template) }
  describe "decoration" do
    it "decorates an EphemeraTemplate" do
      expect(resource.decorate).to be_a described_class
    end
  end
end
