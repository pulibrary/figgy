# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_request do
    filename "MyString"
    state "MyString"
    note "MyText"
    user nil
  end
end
