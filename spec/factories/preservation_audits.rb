# frozen_string_literal: true
FactoryBot.define do
  factory :preservation_audit do
    status { "in_process" }
    extent { "full" }
    batch_id { "bc7f822afbb40747" }
  end
end
