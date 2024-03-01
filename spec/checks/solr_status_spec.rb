# frozen_string_literal: true
require "rails_helper"

RSpec.describe SolrStatus do
  it "doesn't error when Solr's fine" do
    expect { described_class.new.check! }.not_to raise_error
  end
end
