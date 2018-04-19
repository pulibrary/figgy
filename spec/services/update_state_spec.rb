# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdateState do
  let(:col1) { FactoryBot.create_for_repository(:collection) }
  let(:obj1) { FactoryBot.create_for_repository(:scanned_resource, state: ['pending'], member_of_collection_ids: [col1.id]) }
  let(:logger) { Logger.new(nil) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
  end

  describe "#perform" do
    it "updates the state of the member objects" do
      before = query_service.find_by(id: obj1.id)
      expect(before.state).to eq(['pending'])
      expect(before.identifier).to be nil

      described_class.perform(collection_id: col1.id, state: 'complete', logger: logger)

      after = query_service.find_by(id: obj1.id)
      expect(after.state).to eq(['complete'])
      expect(after.identifier).to eq(['ark:/99999/fk4123456'])
    end
  end
end
