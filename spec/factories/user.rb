# frozen_string_literal: true
FactoryBot.define do
  factory :user do
    sequence(:email) { |_n| "#{srand}@princeton.edu" }
    sequence(:uid) { |_n| "#{srand}@princeton.edu" }
    provider { "cas" }

    factory :admin do
      roles { [Role.where(name: "admin").first_or_create] }
    end

    factory :staff do
      roles { [Role.where(name: "staff").first_or_create] }
    end

    factory :campus_patron do
      # All CAS users are campus patrons.
    end

    factory :complete_reviewer do
      email { "complete@example.com" }
      roles { [Role.where(name: "notify_complete").first_or_create] }
    end

    factory :takedown_reviewer do
      email { "takedown@example.com" }
      roles { [Role.where(name: "notify_takedown").first_or_create] }
    end

    factory :reading_room_user do
      roles { [Role.where(name: "reading_room").first_or_create] }
    end
  end
end
