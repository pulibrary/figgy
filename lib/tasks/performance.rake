# frozen_string_literal: true

namespace :performance do
  desc "Performance test persisting."
  begin
    require "ruby-prof"
    require "factory_bot"
    require_relative "../../spec/support/create_for_repository"
    task reindex_profile: :environment do
      raise unless Rails.env.test?
      DataSeeder.new.wipe_metadata!
      Array.new(600) do
        FactoryBot.create_for_repository(:file_set)
      end
      Reindexer.reindex_all
      result = RubyProf.profile do
        Reindexer.reindex_all
      end
      printer = RubyProf::CallStackPrinter.new(result)
      printer.print(File.open("tmp/output.html", "w"))
    end
    task reindex_benchmark: :environment do
      require "benchmark/ips"
      raise unless Rails.env.test?
      DataSeeder.new.wipe_metadata!
      Array.new(30) do
        FactoryBot.create_for_repository(:file_set)
      end
      Reindexer.reindex_all
      Benchmark.ips do |x|
        x.report("reindex_all") do
          Reindexer.reindex_all(logger: Logger.new(IO::NULL))
        end
      end
    end
  rescue LoadError
  end
end
