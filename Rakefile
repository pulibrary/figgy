# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"
require "rubocop/rake_task" if Rails.env.development? || Rails.env.test?

Rails.application.load_tasks
task(:default).clear
task default: [:spec]

if defined? RSpec
  task(:spec).clear
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
  end
end

if defined? RuboCop
  desc "Run RuboCop style checker"
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.requires << "rubocop-rspec"
    task.fail_on_error = true
  end
end

task default: "bundler:audit"
