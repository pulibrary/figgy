# frozen_string_literal: true
namespace :cache do
  task clear: :environment do
    Rails.cache.clear
  end
end
