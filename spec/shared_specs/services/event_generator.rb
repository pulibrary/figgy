# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "an EventGenerator" do
  before do
    raise "record must be set with `let(:record)`" unless
      defined? record
    raise "event_generator must be set with `subject(:event_generator)`" unless
      defined? event_generator
  end

  it "responds all of the composite generator methods with a single record argument" do
    composite_methods = [:derivatives_created, :derivatives_deleted, :record_created, :record_deleted, :record_updated]
    expect(event_generator).to respond_to(*composite_methods).with(1).argument
  end

  it "takes a rabbit exchange client as an argument" do
    obj = event_generator.class.new(Figgy.messaging_client)
    expect(obj.rabbit_exchange.amqp_url).to eq Figgy.messaging_client.amqp_url
  end

  describe "#valid?" do
    context "when given a record it handles" do
      it "returns true" do
        expect(event_generator.valid?(record)).to be true
      end
    end
  end
end
