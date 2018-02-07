# frozen_string_literal: true
namespace :figgy do
  namespace :fixity do
    desc "runs recursive fixity check job"
    task run: :environment do
      CheckFixityRecursiveJob.set(queue: :super_low).perform_later
    end
  end
end
