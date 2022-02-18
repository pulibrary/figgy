# frozen_string_literal: true

require "rails_helper"

RSpec.describe FiggyIndexPresenter do
  let(:request_context) { double }
  let(:config) { Blacklight::Configuration.new }
  let(:presenter) { described_class.new(document, request_context, config) }
  let(:document) do
    SolrDocument.new(:id => 1,
      "title_ssim" => ["title1", "title2"])
  end
  let(:a_proc) { proc {} }

  describe "#label" do
    it "joins multivalued titles" do
      expect(presenter.label(:title_ssim)).to eq "title1; title2"
    end

    # our app doesn't use this functionality that I know of, but for the sake of coverage
    it "runs a proc if given" do
      allow(a_proc).to receive(:call)
      presenter.label(a_proc)
      expect(a_proc).to have_received(:call)
    end

    # this is how it's used for our thumbnail
    it "returns a given html-safe string" do
      expect(presenter.label(ActiveSupport::SafeBuffer.new("<img src=\"default.jpg\" />"))).to eq "<img src=\"default.jpg\" />"
    end
  end
end
