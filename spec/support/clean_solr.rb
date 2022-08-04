# frozen_string_literal: true
RSpec.configure do |config|
  config.before(:each) do
    Blacklight.default_index.connection.delete_by_query("*:*", params: { softCommit: true })
  end
end
