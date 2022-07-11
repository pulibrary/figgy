# frozen_string_literal: true

# Monkey patch AnalyzeJob so that an ActiveJob::DeserializationError is rescued and
# does not cause the job to be moved to the retry queue. This is used mainly for
# OcrRequest blobs that are purged before AnalyzeJob is run.
Rails.application.config.to_prepare do
  ActiveStorage::AnalyzeJob.class_eval do
    discard_on ActiveJob::DeserializationError
  end
end
