# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::GeoserverPublish do
  context "with an unimplemented handler" do
    it "raises an error" do
      factory = ChangeSetPersister::GeoserverPublish::Factory
      expect { factory.new(operation: :bad).new }.to raise_error(NotImplementedError)
    end
  end
end
