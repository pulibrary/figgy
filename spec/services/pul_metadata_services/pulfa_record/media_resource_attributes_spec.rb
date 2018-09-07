# frozen_string_literal: true
require "rails_helper"

describe PulMetadataServices::PulfaRecord::MediaResourceAttributes do
  subject(:media_resource_attributes) { described_class.new(data) }
  let(:source) { file_fixture("pulfa/C0652/c0377.xml").read }
  let(:data) { Nokogiri::XML(source).remove_namespaces! }

  describe "#title" do
    it "extracts the title value for media resource metadata" do
      expect(media_resource_attributes.title).to eq ["Emir Rodriguez Monegal Papers"]
    end
  end
end
