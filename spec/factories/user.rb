# frozen_string_literal: true
FactoryGirl.define do
  factory :user do
    sequence(:email) { |_n| "#{srand}@princeton.edu" }
    sequence(:uid) { |_n| "#{srand}@princeton.edu" }
    provider 'cas'
  end
  factory :admin, parent: :user do
    email "admin@example.com"
    uid 'admin'
  end
end
