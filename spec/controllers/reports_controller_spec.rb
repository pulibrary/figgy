# frozen_string_literal: true
require "rails_helper"

RSpec.describe ReportsController, type: :controller do
  let(:user) { FactoryBot.create(:admin) }

  describe "GET #mms_records" do
    before do
      sign_in(user) if user
    end

    context "when not logged in" do
      let(:user) { nil }
      it "doesn't let folks see it" do
        get :mms_records, format: "json"

        expect(response).to be_forbidden
      end
    end

    context "when using an auth token with the `catalog_sync` group" do
      let(:user) { nil }
      it "renders" do
        auth_token = AuthToken.create!(group: ["catalog_sync"], label: "Catalog Sync Token").token
        stub_catalog(bib_id: "991234563506421")
        _open_mms_record = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "991234563506421")

        get :mms_records, format: "json", params: { auth_token: auth_token }

        expect(response).to be_successful
        expect(JSON.parse(response.body).length).to eq 1
      end
    end

    it "provides a JSON dump of all MMS-ID records" do
      stub_catalog(bib_id: "991234563506421")
      stub_catalog(bib_id: "9911606823506421")
      stub_findingaid(pulfa_id: "C1372_c47202-68234")
      open_mms_record = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "991234563506421")
      other_mms_record = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "9911606823506421", portion_note: "Part")
      private_mms_record = FactoryBot.create_for_repository(:complete_private_scanned_resource, source_metadata_identifier: "991234563506421")
      _pending_mms_record = FactoryBot.create_for_repository(:pending_scanned_resource, source_metadata_identifier: "991234563506421")
      _open_findingaids_record = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "C1372_c47202-68234")

      get :mms_records, format: "json"
      json = JSON.parse(response.body)

      expect(json.length).to eq 2
      expect(json.keys).to contain_exactly "991234563506421", "9911606823506421"
      # Only one resource for this key.
      expect(json["9911606823506421"].first).to eq(
        {
          "iiif_manifest_url" => "http://www.example.com/concern/scanned_resources/#{other_mms_record.id}/manifest",
          "portion_note" => "Part",
          "visibility" => { "value" => "open", "label" => "open", "definition" => "Open to the world. Anyone can view." }
        }
      )
      # Two resources for this key - one is open, one is private. The third
      # isn't complete, so don't display it.
      expect(json["991234563506421"].length).to eq 2
      expect(json["991234563506421"]).to include(
        {
          "iiif_manifest_url" => "http://www.example.com/concern/scanned_resources/#{open_mms_record.id}/manifest",
          "portion_note" => nil,
          "visibility" => { "value" => "open", "label" => "open", "definition" => "Open to the world. Anyone can view." }
        }
      )
      expect(json["991234563506421"]).to include(
        {
          "iiif_manifest_url" => "http://www.example.com/concern/scanned_resources/#{private_mms_record.id}/manifest",
          "portion_note" => nil,
          "visibility" => { "value" => "restricted", "label" => "private", "definition" => "Only privileged users of this application can view." }
        }
      )
    end
  end

  describe "GET #ephemera_data" do
    let(:project) { FactoryBot.create_for_repository(:ephemera_project, member_ids: [box.id, boxless.id]) }
    let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [folder.id]) }
    let(:folder) do
      FactoryBot.create_for_repository(:ephemera_folder, contributor: ["contributor 1", "contributor 2"],
                                                         language: language, genre: genre, subject: subject,
                                                         keywords: ["keyword1", "keyword2"],
                                                         geo_subject: geo_subject,
                                                         geographic_origin: geo_origin,
                                                         transliterated_title: "test transliterated title",
                                                         member_of_collection_ids: [collection.id])
    end
    let(:boxless) { FactoryBot.create_for_repository(:ephemera_folder, title: "boxless folder") }
    let(:language) { EphemeraTerm.new label: "test language" }
    let(:genre) { EphemeraTerm.new label: "test genre" }
    let(:subject) { EphemeraTerm.new label: "test subject" }
    let(:geo_subject) { EphemeraTerm.new label: "test geo subject" }
    let(:geo_origin) { EphemeraTerm.new label: "test geo origin" }
    let(:collection) { FactoryBot.create_for_repository(:collection, title: "test collection") }

    before do
      sign_in user
      project
    end

    it "shows folders" do
      get :ephemera_data, params: { project_id: project.id }, format: "html"
      expect(response).to render_template :ephemera_data
      expect(assigns(:resources).first.id).to eq folder.id
    end
    it "allows downloading a CSV file" do
      get :ephemera_data, params: { project_id: project.id }, format: "csv"
      csv = CSV.parse(response.body, headers: true, header_converters: :symbol)
      row1 = csv.first
      expect(row1[:local_identifier]).to eq "xyz1"
      expect(row1[:barcode]).to eq "12345678901234"
      expect(row1[:ephemera_box_number]).to eq "1"
      expect(row1[:folder_number]).to eq "one"
      expect(row1[:title]).to eq "test folder"
      expect(row1[:transliterated_title]).to eq "test transliterated title"
      expect(row1[:language]).to eq "test language"
      expect(row1[:genre]).to eq "test genre"
      expect(row1[:keywords]).to eq "keyword1;keyword2"
      expect(row1[:subject]).to eq "test subject"
      expect(row1[:geo_subject]).to eq "test geo subject"
      expect(row1[:geographic_origin]).to eq "test geo origin"
      expect(row1[:collection_titles]).to eq "test collection"

      expect(response.headers["Content-Disposition"]).to eq("attachment; filename=\"test-project-data-#{Time.zone.today}.csv\"; filename*=UTF-8''test-project-data-#{Time.zone.today}.csv")
    end
    context "when no project is specified" do
      render_views
      it "has links to each project" do
        get :ephemera_data, params: { formats: :html }
        expect(response).to render_template :ephemera_data
        expect(assigns(:ephemera_projects).first.id).to eq project.id
        expect(response.body).to have_link(project.title.first, href: ephemera_data_path(project.id))
      end
    end
  end

  describe "GET #identifiers_to_reconcile" do
    let(:resource) { FactoryBot.build(:complete_scanned_resource, title: []) }
    let(:resource2) { FactoryBot.build(:complete_scanned_resource, title: []) }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
    let(:data) { "bibid,ark,title\n991234563506421,ark:/99999/fk48675309,Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.\n" }
    before do
      sign_in user
      stub_catalog(bib_id: "991234563506421")
      stub_ezid(shoulder: "99999/fk4", blade: "8675309")
      change_set = ScannedResourceChangeSet.new(resource)
      change_set.validate(source_metadata_identifier: "991234563506421", state: ["complete"])
      change_set_persister.save(change_set: change_set)

      stub_findingaid(pulfa_id: "MC016_c9616")
      change_set = ScannedResourceChangeSet.new(resource2)
      change_set.validate(source_metadata_identifier: "MC016_c9616")
      change_set_persister.save(change_set: change_set)
    end

    it "displays a html view" do
      get :identifiers_to_reconcile
      expect(response).to render_template :identifiers_to_reconcile
    end
    it "allows downloading a CSV file" do
      get :identifiers_to_reconcile, format: "csv"
      expect(response.body).to eq(data)
    end
  end

  describe "GET #ark_report" do
    let(:catalog_resource) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "991234563506421", state: ["complete"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "MC016_c9616", state: ["complete"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource2) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "C0652_c0377", state: ["pending"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource3) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "C0652_c0377", state: ["complete"], visibility: ["restricted"])
      change_set_persister.save(change_set: change_set)
    end
    let(:pulfa_resource4) do
      r = FactoryBot.build(:complete_scanned_resource, title: [])
      change_set = ScannedResourceChangeSet.new(r)
      change_set.validate(source_metadata_identifier: "RBD1_c13076", state: ["complete"])
      change_set_persister.save(change_set: change_set)
    end

    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter) }
    let(:data) { "id,component_id,ark,url\n#{pulfa_resource.id},MC016_c9616,ark:/99999/fk48675309,http://test.host/concern/scanned_resources/#{pulfa_resource.id}/manifest\n" }

    before do
      sign_in user
      stub_catalog(bib_id: "991234563506421")
      stub_findingaid(pulfa_id: "MC016_c9616")
      stub_findingaid(pulfa_id: "C0652_c0377")
      stub_findingaid(pulfa_id: "RBD1_c13076")
      stub_ezid(shoulder: "99999/fk4", blade: "8675309")
      catalog_resource
      pulfa_resource
      pulfa_resource2
      pulfa_resource3

      # create another resource before the since_date
      Timecop.freeze(Time.zone.local(2000))
      pulfa_resource4
      Timecop.return
    end

    it "displays a html view" do
      get :pulfa_ark_report
      expect(response).to render_template :pulfa_ark_report
    end
    it "allows downloading a CSV file with only the open, complete, pulfa resource included" do
      get :pulfa_ark_report, params: { since_date: "2018-01-01" }, format: "csv"
      expect(response.body).to eq(data)
    end

    context "with an empty since_date" do
      it "does not raise an error" do
        get :pulfa_ark_report, params: { since_date: "" }
        expect { response }.not_to raise_error
      end
    end
  end

  describe "GET #collection_item_and_image_count" do
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister), storage_adapter: Valkyrie.config.storage_adapter) }
    # let(:collection) { FactoryBot.build(:collection, title: ["Foo"], id: [SecureRandom.uuid]) }
    let(:collection) { FactoryBot.create_for_repository(:collection, title: ["Foo"], id: [SecureRandom.uuid]) }
    let(:data) do
      "Figgy Collection,\
Open Titles,\
Private Titles,\
Reading Room Titles,\
Princeton Only Titles,\
Open Image Count,\
Private Image Count,\
Reading Room Image Count,\
Princeton Only Image Count\nFoo,,,,,0,0,0,0\n"
    end

    before do
      sign_in user
      5.times do
        file = fixture_file_upload("files/example.tif", "image/tiff")
        FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id, files: [file])
      end
    end
    render_views
    it "displays a html view when no params are passed" do
      get :collection_item_and_image_count
      expect(response).to render_template :collection_item_and_image_count
      expect(response.body).not_to match(/There was a problem generating your report. Valid Collection IDs and at least one valid Date are required./)
    end

    it "displays a html view when params are passed" do
      get :collection_item_and_image_count, params: { collection_ids: collection.id.to_s, date_range: "10/04/2020-10/04/2022" }
      expect(response).to render_template :collection_item_and_image_count
      expect(response.body).to include("Figgy Collection (10/04/2020-10/04/2022)")
    end

    it "allows downloading a CSV file with item and image counts for the collection" do
      get :collection_item_and_image_count, params: { collection_ids: collection.id.to_s, date_range: "10/04/2020-10/04/2022" }, format: "csv"
      expect(response.body).to eq(data)
    end

    it "raises an error if id field is blank" do
      get :collection_item_and_image_count, params: { collection_ids: "", date_range: "10/04/2020-10/04/2022" }
      expect(response.body).to match(/There was a problem generating your report. Valid Collection IDs and at least one valid Date are required./)
    end

    it "raises an error if date_range field is blank" do
      get :collection_item_and_image_count, params: { collection_ids: collection.id.to_s, date_range: "" }
      expect(response.body).to match(/There was a problem generating your report. Valid Collection IDs and at least one valid Date are required./)
    end

    it "raises an error if date is invalid" do
      get :collection_item_and_image_count, params: { collection_ids: collection.id.to_s, date_range: "10/04/2020-30/04/2022" }
      expect(response.body).to match(/There was a problem generating your report. Valid Collection IDs and at least one valid Date are required./)
    end
  end

  describe "GET #dpul_success_dashboard" do
    before do
      body = '{
              "results": [
                  {
                      "date": "2024-07-01",
                      "visitors": 3,
                      "events": 4,
                      "bounce_rate": 4,
                      "pageviews": 4,
                      "visits": 4,
                      "visit_duration": 4
                  },
                  {
                      "date": "2024-07-02",
                      "visitors": 5,
                      "events": 10,
                      "bounce_rate": 4,
                      "pageviews": 4,
                      "visits": 4,
                      "visit_duration": 4
                  },
                  {
                      "date": "2024-07-03",
                      "visitors": 7,
                      "events": 3,
                      "bounce_rate": 4,
                      "pageviews": 4,
                      "visits": 4,
                      "visit_duration": 4
                  }
              ]
            }'

      stub_request(:get, /https:\/\/plausible.io\/api\/v1\/stats\/timeseries.*/)
        .with(
         headers: {
           "Accept" => "*/*",
           "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
           "Authorization" => "Bearer plausible_api_key",
           "Content-Type" => "application/json"
         }
       )
        .to_return(status: 200, body: body, headers: {})

      stub_request(:get, "https://plausible.io/api/v1/stats/breakdown?date=2024-07-01,2024-07-03&interval=date&metrics=visitors,bounce_rate&period=custom&property=visit:source&site_id=dpul.princeton.edu")
        .with(
        headers: {
          "Accept" => "*/*",
          "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Authorization" => "Bearer plausible_api_key",
          "Content-Type" => "application/json"
        }
      )
        .to_return(status: 200, body: body, headers: {})

      sign_in user
    end
    render_views

    it "displays a html view when no params are passed" do
      get :dpul_success_dashboard
      expect(response).to render_template :dpul_success_dashboard
      expect(response.body).not_to match(/There was a problem generating your report. At least one valid Date are required./)
    end

    it "displays a html view when params are passed" do
      get :dpul_success_dashboard, params: { date_range: "07/01/2024-07/03/2024" }
      expect(response).to render_template :dpul_success_dashboard
      expect(response.body).to include("July 01, 2024 - July 03, 2024")
    end

    it "displays an error when an invalid date param is passed" do
      get :dpul_success_dashboard, params: { date_range: "07/01/2024-07/03/2100" }
      expect(response.body).to have_content "There was a problem generating your report. At least one valid Date is required."
    end
  end
end
