# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProxyFileSetDecorator do
  subject(:decorator) { described_class.new(proxy_file_set) }
  let(:proxy_file_set) { ProxyFileSet.new }

  it "does not manage structure" do
    expect(decorator.manageable_structure?).to be false
  end

  it "does not manage files" do
    expect(decorator.manageable_files?).to be false
  end

  it "does not order files" do
    expect(decorator.orderable_files?).to be false
  end
end
