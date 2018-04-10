# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe Bookplate do
  let(:resource_klass) { described_class }
  let(:resource) { FactoryBot.create :bookplate }

  it_behaves_like 'a Valhalla::Resource'
end
