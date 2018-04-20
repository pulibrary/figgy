# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ReportsController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }
  let(:resource) { FactoryBot.build(:complete_scanned_resource, title: []) }
  let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, title: []) }
  let(:change_set_persister) { PlumChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:data) { "bibid,ark,title\n123456,ark:/99999/fk48675309,Earth rites : fertility rites in pre-industrial Britain\n" }

  before do
    sign_in user
    stub_bibdata(bib_id: '123456')
    stub_ezid(shoulder: "99999/fk4", blade: "8675309")

    change_set = ScannedResourceChangeSet.new(resource)
    change_set.validate(source_metadata_identifier: '123456')
    change_set.sync
    change_set_persister.save(change_set: change_set)
  end

  describe "GET #identifiers_to_reconcile" do
    it "displays a html view" do
      get :identifiers_to_reconcile
      expect(response).to render_template :identifiers_to_reconcile
    end
    it "allows downloading a CSV file" do
      get :identifiers_to_reconcile, format: 'csv'
      expect(response.body).to eq(data)
    end
  end
end
