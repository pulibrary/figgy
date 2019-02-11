# frozen_string_literal: true

# spec/simplecov_helper.rb
require "active_support/inflector"
require "simplecov"

class SimpleCovHelper
  def self.report_coverage(base_dir: "./coverage_results")
    SimpleCov.configure do
      minimum_coverage(100)
    end
    new(base_dir: base_dir).merge_results
  end

  attr_reader :base_dir

  def initialize(base_dir:)
    @base_dir = base_dir
  end

  def all_results
    Dir["#{base_dir}/.resultset*.json"]
  end

  def merge_results
    results = all_results.map { |file| SimpleCov::Result.from_hash(JSON.parse(File.read(file))) }
    results = SimpleCov::ResultMerger.merge_results(*results)
    results.format!
    covered_percent = results.covered_percent.round(2)
    return unless covered_percent < SimpleCov.minimum_coverage
    $stderr.printf("Coverage (%.2f%%) is below the expected minimum coverage (%.2f%%).\n", covered_percent, SimpleCov.minimum_coverage)
    Kernel.exit SimpleCov::ExitCodes::MINIMUM_COVERAGE
  end
end

SimpleCovHelper.report_coverage
