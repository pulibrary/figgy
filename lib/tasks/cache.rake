# frozen_string_literal: true
namespace :figgy do
  namespace :cache do
    desc "clears cache"
    task clear: :environment do
      Rails.cache.clear
    end
  end
end
