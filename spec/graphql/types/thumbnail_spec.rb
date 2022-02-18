# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::Thumbnail do
  describe "fields" do
    subject { described_class }
    it { is_expected.to have_field(:id).of_type(String) }
    it { is_expected.to have_field(:iiifServiceUrl).of_type(String) }
    it { is_expected.to have_field(:thumbnailUrl).of_type(String) }
  end
end
