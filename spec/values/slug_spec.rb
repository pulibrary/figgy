# frozen_string_literal: true

require "rails_helper"

describe Slug do
  subject(:slug) { described_class.new("test-project-1234") }

  describe "#valid?" do
    context "with a valid slug" do
      it "confirms that the slug is valid" do
        expect(slug.valid?).to be true
      end
    end
  end
end
