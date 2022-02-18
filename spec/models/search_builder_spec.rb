# frozen_string_literal: true

require "rails_helper"

describe SearchBuilder do
  subject(:search_builder) { described_class.new scope }
  let(:user_params) { {} }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config }
end
