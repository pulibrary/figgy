# frozen_string_literal: true
require "rails_helper"

RSpec.describe ProxyFileDecorator do
  subject(:decorator) { described_class.new(proxy_file) }
  let(:proxy_file) { ProxyFile.new }

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
