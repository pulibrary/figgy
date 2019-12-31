# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraFieldChangeSet do
  subject(:change_set) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:ephemera_field) }

  it_behaves_like "an optimistic locking change set"
end
