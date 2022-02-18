# frozen_string_literal: true

namespace :figgy do
  namespace :clean do
    desc "Clean Blacklight searches older than a given number of days."
    task :old_searches, [:days_old] => [:environment] do |_t, args|
      args.with_defaults(days_old: 7)
      CleanSearchesJob.set(queue: :low).perform_later(days_old: args[:days_old].to_i)
    end

    desc "Clean guest user accounts older than a given number of days."
    task :old_guest_users, [:days_old] => [:environment] do |_t, args|
      args.with_defaults(days_old: 7)
      CleanGuestUsersJob.set(queue: :low).perform_later(days_old: args[:days_old].to_i)
    end

    desc "Clean dead Sidekiq Queues."
    task :dead_queues do
      CleanDeadQueuesJob.set(queue: :low).perform_later
    end
  end
end
