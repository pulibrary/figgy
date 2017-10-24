# frozen_string_literal: true
require 'rails_helper'

RSpec.describe PlumDerivativeMover do
  let(:old) { Rails.root.join('spec', 'fixtures', 'files', 'bibdata', '123456.jsonld') }

  before do
    allow(FileUtils).to receive(:cp).and_call_original
    allow(FileUtils).to receive(:ln).and_call_original
  end

  context "in test" do
    let(:new) { Rails.root.join('tmp', 'copied.jsonld') }

    it "copies the file" do
      described_class.link_or_copy(old, new)
      expect(FileUtils).not_to have_received(:ln)
      expect(FileUtils).to have_received(:cp)
    end
  end
  context "in production" do
    let(:new) { Rails.root.join('tmp', 'linked.jsonld') }

    before do
      allow(Rails.env).to receive(:production?).and_return(true)
    end
    it "hardlinks the file" do
      described_class.link_or_copy(old, new)
      expect(FileUtils).not_to have_received(:cp)
      expect(FileUtils).to have_received(:ln)
    end
  end
end
