# frozen_string_literal: true
namespace :cache do
  namespace :clear do
    desc "Clear cache"
    task run: :environment do
      Rails.cache.clear
    end
  end
end
