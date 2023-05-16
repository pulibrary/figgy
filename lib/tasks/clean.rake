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
    task dead_queues: :environment do
      CleanDeadQueuesJob.set(queue: :low).perform_later
    end

    desc "Clean expired uploaded files."
    task expired_local_files: :environment do
      expiration_time = Tus::Server.opts[:expiration_time]
      tus_storage     = Tus::Server.opts[:storage]
      expiration_date = Time.now.utc - expiration_time

      tus_storage.expire_files(expiration_date)
    end
  end
end
