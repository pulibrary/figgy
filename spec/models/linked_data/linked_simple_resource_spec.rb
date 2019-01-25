# frozen_string_literal: true
require "rails_helper"

RSpec.describe LinkedData::LinkedSimpleResource do
  subject(:linked_ephemera_folder) { described_class.new(resource: resource) }
  let(:resource) { FactoryBot.create_for_repository(:simple_resource, date_range: date_range) }
  let(:date_range) { DateRange.new(start: "2013", end: "2017") }
  let(:resource_factory) { :simple_resource }

  it_behaves_like "LinkedData::Resource::WithDateRange"
end
