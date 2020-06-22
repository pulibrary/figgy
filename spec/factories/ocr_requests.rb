# frozen_string_literal: true

FactoryBot.define do
  factory :ocr_request do
    filename "sample.pdf"
    state "enqueued"
    note "notes"
    user nil

    transient do
      file nil
    end

    after(:create) do |resource, evaluator|
      if evaluator.file.present?
        resource.pdf.attach(io: File.open(evaluator.file), filename: File.basename(evaluator.file))
      end
    end
  end
end
