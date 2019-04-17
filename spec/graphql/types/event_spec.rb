# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::Event do
  describe "fields" do
    subject { described_class }
    it { is_expected.to have_field(:id).of_type(String) }
    it { is_expected.to have_field(:messages) }
    it { is_expected.to have_field(:modifiedResources) }
  end
end
