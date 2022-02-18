# frozen_string_literal: true

namespace :figgy do
  namespace :cache do
    task clear: :environment do
      Rails.cache.clear
    end
  end
end
