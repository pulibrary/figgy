# frozen_string_literal: true
RSpec.configure do |config|
  config.before(:each) do
    Valkyrie::MetadataAdapter.adapters.values.each do |adapter|
      next unless adapter.is_a?(Valkyrie::Persistence::Memory::MetadataAdapter)
      adapter.cache = {}
    end
  end
end
