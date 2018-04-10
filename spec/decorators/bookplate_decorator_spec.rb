# frozen_string_literal: true
require 'rails_helper'

RSpec.describe BookplateDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:bookplate) }
  let(:resource_klass) { Bookplate }

  it_behaves_like 'a Valhalla::ResourceDecorator'
end
