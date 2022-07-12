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
    SimpleCov.collate all_results
  end
end

SimpleCovHelper.report_coverage
