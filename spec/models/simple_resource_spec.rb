# frozen_string_literal: true
require 'rails_helper'
require 'valkyrie/specs/shared_specs'

RSpec.describe SimpleResource do
  let(:resource_klass) { described_class }
  let(:resource) { FactoryBot.create :simple_resource }

  it_behaves_like 'a Valhalla::Resource'
end
