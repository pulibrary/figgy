# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogController do
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  describe "#index" do
    render_views
    it "finds all public documents" do
      persister.save(resource: FactoryBot.build(:complete_scanned_resource))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 1
    end
    it "can find documents via JSON" do
      get :index, params: {q: "", format: :json}

      expect(response).to be_successful
    end
  end

  describe "#blacklight_config" do
    it "has a default per_page of 20" do
      expect(controller.blacklight_config.default_per_page).to eq 20
    end
  end

  describe "#iiif_search" do
    render_views
    context "when given a private document" do
      it "doesn't work" do
        child = FactoryBot.create_for_repository(:file_set, ocr_content: "Content", hocr_content: "<html></html>")
        parent = FactoryBot.create_for_repository(:pending_scanned_resource, member_ids: child.id, ocr_language: :eng)

        persister.save_all(resources: [child, parent])

        get :iiif_search, params: {solr_document_id: parent.id, q: "Content"}

        expect(response).not_to be_successful
        expect(response).to redirect_to "http://test.host/users/auth/cas"
      end
    end

    it "finds OCR documents" do
      file_set = FactoryBot.create_for_repository(:file_set, ocr_content: "Content", hocr_content: "<html></html>")
      child = FactoryBot.create_for_repository(:file_set, ocr_content: "Content", hocr_content: "<html></html>")
      parent = FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: child.id, ocr_language: :eng)

      persister.save_all(resources: [child, parent, file_set])

      get :iiif_search, params: {solr_document_id: parent.id, q: "Content"}

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response["resources"].length).to eq 1
      expect(json_response["resources"][0]["on"]).to eq "http://www.example.com/concern/scanned_resources/#{parent.id}/manifest/canvas/#{child.id}#xywh=0,0,0,0"
    end

    it "can perform hit highlighting" do
      child = FactoryBot.create_for_repository(:file_set, ocr_content: "Content", hocr_content: "<html><body><span class='ocrx_word' title='bbox 1 2 3 4'>Content</span></body></html>")
      parent = FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: child.id, ocr_language: :eng)

      persister.save_all(resources: [child, parent])

      get :iiif_search, params: {solr_document_id: parent.id, q: "Content"}

      expect(response).to be_successful
      json_response = JSON.parse(response.body)
      expect(json_response["resources"].length).to eq 1
      expect(json_response["resources"][0]["on"]).to eq "http://www.example.com/concern/scanned_resources/#{parent.id}/manifest/canvas/#{child.id}#xywh=1,2,2,2"
    end
  end

  describe "#index" do
    it "can search by source metadata identifier" do
      stub_bibdata(bib_id: "123456")
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, source_metadata_identifier: "123456"))

      get :index, params: {q: "123456"}

      expect(assigns(:document_list).length).to eq 1
    end
    context "with imported metadata" do
      render_views
      it "can search by imported metadata title" do
        stub_bibdata(bib_id: "123456")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        output = persister.save(resource: FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "123456", import_metadata: true))

        get :index, params: {q: "Earth rites"}

        expect(response.body).to have_selector "td", text: "Bord, Janet, 1945-"
        expect(assigns(:document_list).length).to eq 1
        facets = assigns(:response)["facet_counts"]["facet_fields"]
        expect(facets["state_ssim"]).to eq ["complete", 1]
        expect(facets["display_subject_ssim"]).to eq [output.imported_metadata[0].subject.first, 1]
        expect(facets["visibility_ssim"]).to eq ["open", 1]
      end
    end
    it "can search by local identifiers" do
      persister.save(resource: FactoryBot.create_for_repository(:complete_scanned_resource, local_identifier: "p3b593k91p"))

      get :index, params: {q: "p3b593k91p"}
      expect(assigns(:document_list).length).to eq 1
    end
    context "with metadata imported from voyager" do
      it "can search by imported local identifiers" do
        stub_bibdata(bib_id: "8543429")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        persister.save(resource: FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "8543429", import_metadata: true))
        get :index, params: {q: "cico:xjt"}
        expect(assigns(:document_list).length).to eq 1
      end
      it "can search by call number" do
        stub_bibdata(bib_id: "10001789")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        persister.save(resource: FactoryBot.create_for_repository(:scanned_map, state: "complete", title: [], source_metadata_identifier: "10001789", import_metadata: true))
        get :index, params: {q: "g8731"}
        expect(assigns(:document_list).length).to eq 1
      end
      it "can search by various imported fields" do
        stub_bibdata(bib_id: "10001789")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        persister.save(resource: FactoryBot.create_for_repository(:scanned_map, state: "complete", title: [], source_metadata_identifier: "10001789", import_metadata: true))
        get :index, params: {q: "Stationery"}
        expect(assigns(:document_list).length).to eq 1

        get :index, params: {q: "lighthouses"}
        expect(assigns(:document_list).length).to eq 1
      end
    end
    context "with metadata imported from pulfa" do
      it "can search by box and folder numbers" do
        stub_pulfa(pulfa_id: "AC044_c0003")
        stub_ezid(shoulder: "99999/fk4", blade: "8543429")
        persister.save(resource: FactoryBot.create_for_repository(:complete_scanned_resource, title: [], source_metadata_identifier: "AC044_c0003", import_metadata: true))
        get :index, params: {q: "Box 1 Folder 2"}
        expect(assigns(:document_list).length).to eq 1
      end
    end
    context "recordings with imported metadata" do
      let(:recording_properties) { {member_ids: track.id, state: "complete", source_metadata_identifier: "3515072", import_metadata: true} }
      let(:recording) { persister.save(resource: FactoryBot.create_for_repository(:recording, **recording_properties)) }
      let(:track) { FactoryBot.create_for_repository(:file_set, title: "Title not in imported metadata") }
      before do
        stub_bibdata(bib_id: "3515072")
        stub_ezid(shoulder: "99999/fk4", blade: "1234567")
        recording
      end

      it "can find by imported metadata" do
        get :index, params: {q: "Sheena is a punk rocker"}
        expect(assigns(:document_list).length).to eq 1
      end

      it "can find by track name" do
        get :index, params: {q: "Title not in imported metadata?"}
        expect(assigns(:document_list).length).to eq 1
      end
    end
    it "can search by ARK" do
      stub_bibdata(bib_id: "123456")
      stub_ezid(shoulder: "99999/fk4", blade: "123456")
      persister.save(resource: FactoryBot.create_for_repository(:complete_scanned_resource, source_metadata_identifier: "123456", import_metadata: true))

      get :index, params: {q: "ark:/99999/fk4123456"}

      expect(assigns(:document_list).length).to eq 1

      get :index, params: {q: "fk4123456"}
      expect(assigns(:document_list).length).to eq 1
    end
    it "can search by non-imported title" do
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, title: "Tësting This"))

      get :index, params: {q: "Testing"}

      expect(assigns(:document_list).length).to eq 1
    end

    context "with indexed completed ephemera folders" do
      before do
        persister.save(resource: FactoryBot.build(:ephemera_folder, folder_number: "24", barcode: "123456789abcde", state: "complete"))
      end

      it "can search by barcode" do
        get :index, params: {q: "123456789abcde"}

        expect(assigns(:document_list).length).to eq 1
      end

      it "can search by folder label" do
        get :index, params: {q: "folder 24"}

        expect(assigns(:document_list).length).to eq 1
      end
    end

    it "can sort by title" do
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, title: "Resource A"))
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, title: "Resource B"))

      get :index, params: {q: "resource", sort: "title_ssort asc"}
      expect(assigns(:document_list).map { |r| r.resource.title.first }).to eq(["Resource A", "Resource B"])

      get :index, params: {q: "resource", sort: "title_ssort desc"}
      expect(assigns(:document_list).map { |r| r.resource.title.first }).to eq(["Resource B", "Resource A"])
    end

    it "allows multiple anonymous users to search" do
      u1 = User.new uid: "guest_123"
      u1.save(validate: false)
      sign_in u1
      get :index, params: {q: ""}
      expect(response).to be_successful

      u2 = User.new uid: "guest_456"
      u2.save(validate: false)
      sign_in u2
      get :index, params: {q: ""}
      expect(response).to be_successful
    end

    it "doesn't display claimed_by if not logged in" do
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, claimed_by: "Donatello"))
      get :index, params: {q: ""}
      expect(assigns(:document_list).length).to eq 1
      queries = assigns(:response)["facet_counts"]["facet_queries"]
      expect(queries.keys.select { |x| x.include?("claimed") }).to be_empty
    end

    it "displays claimed_by if logged in" do
      u = FactoryBot.create(:admin)
      sign_in u
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, claimed_by: "Donatello"))
      persister.save(resource: FactoryBot.build(:complete_scanned_resource, claimed_by: u.uid))
      persister.save(resource: FactoryBot.build(:complete_scanned_resource))
      get :index, params: {q: ""}
      facet_queries = assigns(:response)["facet_counts"]["facet_queries"]
      expect(facet_queries).not_to be_empty
      # Unclaimed
      expect(facet_queries["-claimed_by_ssim:[* TO *]"]).to eq 1
      # Claimed
      expect(facet_queries["claimed_by_ssim:[* TO *]"]).to eq 2
      # Claimed by Me
      expect(facet_queries["claimed_by_ssim:#{u.uid}"]).to eq 1
    end
  end

  describe "FileSet behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end
    it "doesn't display indexed FileSets" do
      persister.save(resource: FactoryBot.build(:file_set))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 0
    end
  end

  describe "numismatics ajax lookups" do
    context "staff user" do
      it "can access solr metadata for numismatics place" do
        sign_in FactoryBot.create(:staff)
        persister.save(resource: FactoryBot.build(:numismatic_place))
        get :index, params: {q: "", all_models: "true", f: {human_readable_type_ssim: ["Place"]}}
        expect(assigns(:document_list).length).to eq 1
      end
    end
    context "anonymous user" do
      it "cannot access solr metadata for numismatics place" do
        persister.save(resource: FactoryBot.build(:numismatic_place))
        get :index, params: {q: "", all_models: "true", f: {human_readable_type_ssim: ["Place"]}}
        expect(assigns(:document_list).length).to eq 0
      end
    end
  end

  describe "EphemeraFolder behavior" do
    context "when not an admin" do
      it "displays a completed EphemeraFolder" do
        persister.save(resource: FactoryBot.build(:ephemera_folder, state: "complete"))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end

      it "does not display incomplete EphemeraFolders" do
        persister.save(resource: FactoryBot.build(:ephemera_folder))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 0
      end

      it "does not display EphemeraBoxes" do
        persister.save(resource: FactoryBot.build(:ephemera_box, state: "all_in_production"))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 0
      end
    end

    context "when an admin" do
      before do
        sign_in FactoryBot.create(:admin)
      end
      it "displays indexed EphemeraFolders" do
        folder = persister.save(resource: FactoryBot.build(:ephemera_folder))
        persister.save(resource: FactoryBot.build(:ephemera_box, member_ids: folder.id))
        persister.save(resource: folder)

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 2
      end

      it "displays all_in_production  EphemeraBoxes" do
        persister.save(resource: FactoryBot.build(:ephemera_box, state: "all_in_production"))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end

      context "with a non-Latin title which has been transliterated" do
        let(:title) { "Что делать?" }
        let(:transliterated_title) { "Chto delat'?" }

        before do
          persister.save(resource: FactoryBot.build(:ephemera_folder, title: title, transliterated_title: transliterated_title))
        end

        it "can search by the non-Latin title" do
          get :index, params: {q: "Что"}
          expect(assigns(:document_list).length).to eq 1
        end

        it "can search by the transliterated title" do
          get :index, params: {q: "Chto"}
          expect(assigns(:document_list).length).to eq 1
        end
      end
    end
  end

  describe "EphemeraBox behavior" do
    context "as an administrator" do
      before do
        sign_in FactoryBot.create(:admin)
      end
      it "displays indexed EphemeraBoxes" do
        persister.save(resource: FactoryBot.build(:ephemera_box))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end

      it "indexes by barcode" do
        persister.save(resource: FactoryBot.build(:ephemera_box, barcode: "abcde012345678"))
        get :index, params: {q: "abcde012345678"}

        expect(assigns(:document_list).length).to eq 1
      end
    end

    context "within an incomplete EphemeraBox" do
      let(:ephemera_folder) { FactoryBot.build(:ephemera_folder, state: "complete") }
      let(:ephemera_box) { FactoryBot.build(:ephemera_box, state: "new") }
      before do
        box = persister.save(resource: ephemera_box)
        folder = persister.save(resource: ephemera_folder)
        box.member_ids = folder.id
        persister.save(resource: box)
        persister.save(resource: folder)
      end
      it "does display complete EphemeraFolders" do
        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end
    end

    context "within a complete EphemeraBox" do
      let(:ephemera_folder) { FactoryBot.build(:ephemera_folder, folder_number: "99", state: "complete") }
      let(:ephemera_box) { FactoryBot.build(:ephemera_box, box_number: "42", state: "all_in_production") }
      before do
        box = persister.save(resource: ephemera_box)
        folder = persister.save(resource: ephemera_folder)
        box.member_ids = folder.id
        persister.save(resource: box)
        persister.save(resource: folder)
      end
      it "does display complete EphemeraFolders" do
        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end

      it "retrieves folders by box/folder label" do
        get :index, params: {q: "box 42 folder 99"}

        expect(assigns(:document_list).length).to eq 1
      end
    end

    context "an incomplete folder within a complete box" do
      let(:ephemera_folder) { FactoryBot.build(:ephemera_folder, state: "needs_qa") }
      let(:ephemera_box) { FactoryBot.build(:ephemera_box, state: "all_in_production") }
      before do
        box = persister.save(resource: ephemera_box)
        folder = persister.save(resource: ephemera_folder)
        box.member_ids = folder.id
        persister.save(resource: box)
        persister.save(resource: folder)
      end
      it "does display incomplete folders" do
        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end
    end
  end

  describe "ScannedMap behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end
    it "displays indexed ScannedMaps" do
      persister.save(resource: FactoryBot.build(:scanned_map))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 1
    end
  end

  describe "FileMetadata behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end
    it "doesn't display indexed FileMetadata nodes" do
      persister.save(resource: FileMetadata.new)

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 0
    end
  end

  describe "SimpleResource behavior" do
    it "does not display a Simple Resource in draft state" do
      persister.save(resource: FactoryBot.build(:simple_resource, state: "draft"))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 0
    end
    it "does display a Simple Resource in published state" do
      persister.save(resource: FactoryBot.build(:simple_resource, state: "complete"))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 1
    end
  end

  describe "incomplete record behavior" do
    context "as a user" do
      before do
        sign_in FactoryBot.create(:user)
      end
      it "doesn't display incomplete items" do
        persister.save(resource: FactoryBot.build(:pending_scanned_resource))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 0
      end
    end
    context "as an admin" do
      before do
        sign_in FactoryBot.create(:admin)
      end
      it "displays incomplete items" do
        persister.save(resource: FactoryBot.build(:pending_scanned_resource))

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
      end
    end
  end

  describe "child resource behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end

    context "with a scanned resource" do
      it "doesn't display children of parented resources" do
        child = persister.save(resource: FactoryBot.build(:complete_scanned_resource))
        parent = persister.save(resource: FactoryBot.build(:complete_scanned_resource, member_ids: child.id))
        # Re-save to get member_of to index, not necessary if going through
        #   ChangeSetPersister.
        persister.save(resource: child)

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 1
        expect(assigns(:document_list).first.resource.id).to eq parent.id
      end
    end

    context "with a numismatic issue" do
      it "retrieves both issues and coins" do
        child = persister.save(resource: FactoryBot.build(:complete_open_coin))
        parent = persister.save(resource: FactoryBot.build(:complete_open_numismatic_issue, member_ids: child.id))
        # Re-save to get member_of to index, not necessary if going through
        #   ChangeSetPersister.
        persister.save(resource: child)

        get :index, params: {q: ""}

        expect(assigns(:document_list).length).to eq 2
        expect(assigns(:document_list).map(&:id)).to contain_exactly(parent.id.to_s, child.id.to_s)
      end
    end
  end

  describe "Collection behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end

    it "displays indexed collections" do
      persister.save(resource: FactoryBot.build(:collection))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 1
    end
    context "when a resource has a collection" do
      render_views
      it "facets on it" do
        collection = persister.save(resource: FactoryBot.build(:collection))
        persister.save(resource: FactoryBot.build(:complete_scanned_resource, member_of_collection_ids: [collection.id]))

        get :index, params: {q: ""}

        expect(response.body).to have_selector ".facet-field-heading", text: "Collections"
        expect(response.body).to have_selector ".facet_select", text: collection.title.first
      end
    end
  end

  describe "ArchivalMediaCollection behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end

    it "displays indexed ArchivalMediaCollections" do
      persister.save(resource: FactoryBot.build(:archival_media_collection))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 1
    end
  end

  describe "Recording behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end

    it "displays indexed Recordings" do
      persister.save(resource: FactoryBot.build(:recording))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 1
    end
  end

  describe "Template behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end

    it "does not display Templates" do
      persister.save(resource: FactoryBot.build(:template))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 0
    end
  end

  describe "Numismatics::Accession behavior" do
    before do
      sign_in FactoryBot.create(:admin)
    end
    it "doesn't display indexed Numismatics::Accessions" do
      persister.save(resource: FactoryBot.build(:numismatic_accession))

      get :index, params: {q: ""}

      expect(assigns(:document_list).length).to eq 0
    end
  end

  describe "nested catalog file_set paths" do
    context "when you have permission to view file sets" do
      before do
        sign_in FactoryBot.create(:admin)
      end
      it "loads the parent document when given an ID" do
        child = persister.save(resource: FactoryBot.build(:file_set))
        parent = persister.save(resource: FactoryBot.build(:complete_scanned_resource, member_ids: child.id))

        get :show, params: {parent_id: parent.id, id: child.id}

        expect(assigns(:parent_document)).not_to be_nil
      end
    end
    context "as a public user" do
      it "redirects and displays a warning that the item is private" do
        child = persister.save(resource: FactoryBot.build(:file_set))
        parent = persister.save(resource: FactoryBot.build(:complete_scanned_resource, member_ids: child.id))

        expect { get :show, params: {parent_id: parent.id, id: child.id} }.not_to raise_error
        expect(response.status).to be 302
        expect(flash[:alert]).to eq "You do not have sufficient access privileges to read this document, which has been marked private."
      end
    end
  end

  describe "#show" do
    context "when rendered for an admin auth token" do
      render_views
      it "renders" do
        authorization_token = AuthToken.create!(group: ["admin"], label: "Admin Token")
        resource = persister.save(resource: FactoryBot.build(:pending_private_scanned_resource, workflow_note: WorkflowNote.new(author: "Shakespeare", note: "Test Comment")))

        get :show, params: {id: resource.id, format: :json, auth_token: authorization_token.token}
        expect(response).to be_successful
      end
    end
    context "when rendered for an admin" do
      before do
        sign_in FactoryBot.create(:admin)
      end
      render_views
      it "renders administration buttons" do
        resource = persister.save(resource: FactoryBot.build(:complete_scanned_resource, workflow_note: WorkflowNote.new(author: "Shakespeare", note: "Test Comment"), ocr_language: "eng"))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_link "Edit This Scanned Resource", href: edit_scanned_resource_path(resource)
        expect(response.body).to have_link "Delete This Scanned Resource", href: scanned_resource_path(resource)
        expect(response.body).to have_link "File Manager", href: file_manager_scanned_resource_path(resource)
        expect(response.body).to have_link "Order Manager", href: order_manager_scanned_resource_path(resource)
        expect(response.body).to have_link "Structure Manager", href: structure_scanned_resource_path(resource)
        expect(response.body).to have_link "Attach Scanned Resource", href: parent_new_scanned_resource_path(resource)
        expect(response.body).to have_content "Review and Approval"
        expect(response.body).to have_content "Shakespeare"
        expect(response.body).to have_content "Test Comment"
      end

      it "renders RDF views" do
        stub_bibdata(bib_id: "123456")
        stub_bibdata_context
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        collection = FactoryBot.create_for_repository(:collection)
        resource = FactoryBot.create_for_repository(
          :complete_scanned_resource,
          source_metadata_identifier: "123456",
          import_metadata: true,
          portion_note: "Test",
          nav_date: "Test",
          member_of_collection_ids: collection.id
        )
        resource.primary_imported_metadata.title += ["test"]
        resource = persister.save(resource: resource)

        get :show, params: {id: resource.id.to_s, format: :jsonld}

        expect(response).to be_successful
        json_body = MultiJson.load(response.body, symbolize_keys: true)
        expect(json_body[:title][0][:@value]).to eq "Earth rites : fertility rites in pre-industrial Britain"
        expect(json_body[:title][1][:@value]).to eq "test"
        expect(json_body[:identifier]).not_to be_blank
        expect(json_body[:scopeNote]).not_to be_blank
        expect(json_body[:navDate]).not_to be_blank
        expect(json_body[:edm_rights][:@id]).to eq RightsStatements.no_known_copyright.to_s
        expect(json_body[:edm_rights][:@type]).to eq "dcterms:RightsStatement"
        expect(json_body[:edm_rights][:pref_label]).to eq "No Known Copyright"
        expect(json_body[:memberOf][0][:@id]).to eq "http://www.example.com/catalog/#{collection.id}"
        expect(json_body[:memberOf][0][:@type]).to eq "pcdm:Collection"
        expect(json_body[:memberOf][0][:title]).to eq collection.title.first

        get :show, params: {id: resource.id.to_s, format: :nt}
        expect(response).to be_successful

        get :show, params: {id: resource.id.to_s, format: :ttl}
        expect(response).to be_successful

        empty_resource = persister.save(resource: FactoryBot.build(:complete_scanned_resource))
        get :show, params: {id: empty_resource.id.to_s, format: :jsonld}
        expect(response).to be_successful

        collection = persister.save(resource: FactoryBot.build(:collection))
        get :show, params: {id: collection.id.to_s, format: :jsonld}
        expect(response).to be_successful

        folder = persister.save(resource: FactoryBot.build(:ephemera_folder))
        persister.save(resource: FactoryBot.build(:ephemera_project, member_ids: [folder.id]))
        get :show, params: {id: folder.id.to_s, format: :jsonld}
        expect(response).to be_successful
        json_body = MultiJson.load(response.body, symbolize_keys: true)
        expect(json_body[:local_identifier][0]).to eq "xyz1"

        simple_resource = persister.save(resource: FactoryBot.build(:simple_resource, author: "Test Author", part_of: ArkWithTitle.new(identifier: "https://www.example.com", title: "Test")))
        get :show, params: {id: simple_resource.id.to_s, format: :jsonld}
        expect(response).to be_successful
        json_body = MultiJson.load(response.body, symbolize_keys: true)
        expect(json_body[:author]).not_to be_blank
        expect(json_body[:pdf_type]).to be_blank
        expect(json_body[:part_of][0][:@id]).to eq "https://www.example.com"
        expect(json_body[:part_of][0][:title]).to eq "Test"
      end

      it "renders for a FileSet" do
        resource = persister.save(resource: FactoryBot.build(:file_set))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_link "Edit This File Set", href: edit_file_set_path(resource)
        expect(response.body).to have_link "Delete This File Set", href: file_set_path(resource)
        expect(response.body).not_to have_link "File Manager"
      end

      it "renders for a Collection" do
        resource = persister.save(resource: FactoryBot.build(:collection))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_link "Edit This Collection", href: edit_collection_path(resource)
        expect(response.body).to have_link "Delete This Collection", href: collection_path(resource)
        expect(response.body).not_to have_link "File Manager"
      end

      it "renders for an Ephemera Folder" do
        resource = persister.save(resource: FactoryBot.build(:ephemera_folder))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_content "Review and Approval"
      end

      it "renders for an Ephemera Project" do
        resource = persister.save(resource: FactoryBot.build(:ephemera_project))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_selector "h1", text: resource.title.first
      end

      it "renders for an Ephemera Box" do
        resource = persister.save(resource: FactoryBot.build(:ephemera_box))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_content "Review and Approval"
        expect(response.body).to have_link "Create New Folder Template"
      end

      it "renders for a Recording" do
        file_set = FactoryBot.create_for_repository(:file_set)
        resource = persister.save(resource: FactoryBot.create_for_repository(:recording, member_ids: file_set.id))
        playlist = FactoryBot.create_for_repository(:playlist, member_ids: FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_set.id).id)

        get :show, params: {id: resource.id.to_s}

        expect(response.body).to have_selector "h2", text: "Playlists"
        expect(response.body).to have_link playlist.title.first, href: "/catalog/#{playlist.id}"
      end
    end
    context "when rendered for a user" do
      render_views
      it "doesn't render the workflow panel" do
        resource = persister.save(resource: FactoryBot.build(:complete_open_scanned_resource))

        get :show, params: {id: resource.id.to_s}

        expect(response.body).not_to have_content "Review and Approval"
      end
    end
  end

  describe "#has_search_parameters?" do
    context "when only a q is passed" do
      it "returns true" do
        get :index, params: {q: ""}

        expect(controller).to have_search_parameters
      end
    end

    context "when not logged in" do
      it "does not display resources without the `public` read_groups" do
        FactoryBot.create_for_repository(:complete_private_scanned_resource)

        get :index, params: {q: ""}

        expect(assigns(:document_list)).to be_empty
      end
    end

    context "when logged in as an admin" do
      it "displays all resources" do
        user = FactoryBot.create(:admin)
        persister.save(resource: FactoryBot.build(:complete_scanned_resource, read_groups: nil, edit_users: nil))

        sign_in user
        get :index, params: {q: ""}

        expect(assigns(:document_list)).not_to be_empty
      end
      it "displays private resources even in index read-only mode" do
        user = FactoryBot.create(:admin)
        persister.save(resource: FactoryBot.build(:pending_private_scanned_resource))
        allow(Figgy).to receive(:index_read_only?).and_return(true)

        sign_in user
        get :index, params: {q: ""}

        expect(assigns(:document_list)).not_to be_empty
      end
    end
    context "when logged in" do
      it "displays resources which the user can edit" do
        user = FactoryBot.create(:user)
        persister.save(resource: FactoryBot.build(:complete_scanned_resource, read_groups: nil, edit_users: user.user_key))

        sign_in user
        get :index, params: {q: ""}

        expect(assigns(:document_list)).not_to be_empty
      end
      it "displays resources which are explicitly given permission to that user" do
        user = FactoryBot.create(:user)
        persister.save(resource: FactoryBot.build(:complete_scanned_resource, read_groups: nil, read_users: user.user_key))

        sign_in user
        get :index, params: {q: ""}

        expect(assigns(:document_list)).not_to be_empty
      end
    end
  end

  describe "manifest lookup" do
    context "when the manifest is found" do
      let(:resource) { persister.save(resource: FactoryBot.build(:complete_scanned_resource, identifier: ["ark:/99999/12345"])) }

      before do
        resource
      end

      it "redirects to the manifest" do
        get :lookup_manifest, params: {prefix: "ark:", naan: "99999", arkid: "12345"}
        expect(response).to redirect_to "http://test.host/concern/scanned_resources/#{resource.id}/manifest"
      end
      it "doesn't redirect when no_redirect is set" do
        get :lookup_manifest, params: {prefix: "ark:", naan: "99999", arkid: "12345", no_redirect: "true"}
        expect(response).to be_successful
        expect(JSON.parse(response.body)["url"]).to eq "http://test.host/concern/scanned_resources/#{resource.id}/manifest"
      end
    end

    context "when the manifest is not found" do
      it "sends a 404 error" do
        get :lookup_manifest, params: {prefix: "ark:", naan: "99999", arkid: "99999"}
        expect(response.status).to be 404
      end
    end
  end

  describe "numismatics" do
    let(:coin) { persister.save(resource: FactoryBot.build(:complete_open_coin, coin_metadata)) }
    let(:issue_attr) { issue_metadata.merge(member_ids: [coin.id]) }
    let(:issue) { persister.save(resource: FactoryBot.build(:complete_open_numismatic_issue, issue_attr)) }
    let(:issue_metadata) do
      {
        earliest_date: "2017",
        latest_date: "2018",
        color: "issue-color",
        denomination: "issue-denomination",
        depositor: "issue-depositor",
        edge: "issue-edge",
        era: "issue-era",
        identifier: "issue-identifier",
        metal: "issue-metal",
        object_date: "issue-object-date",
        object_type: "issue-type",
        obverse_figure: "issue-obverse-figure",
        obverse_figure_relationship: "issue-obverse-figure-relationship",
        obverse_figure_description: "issue-obverse-figure-description",
        obverse_legend: "issue-obv-legend",
        obverse_orientation: "issue-obverse-orientation",
        obverse_part: "issue-obverse-part",
        obverse_symbol: "issue-obverse-symbol",
        replaces: "issue-replaces",
        reverse_figure: "issue-rev-figure",
        reverse_figure_description: "issue-rev-figure-description",
        reverse_figure_relationship: "issue-rev-figure-relationship",
        reverse_legend: "issue-rev-legend",
        reverse_orientation: "issue-reverse-orientation",
        reverse_part: "issue-rev-part",
        reverse_symbol: "issue-rev-symbol",
        series: "issue-series",
        shape: "issue-series",
        workshop: "issue-workshop"
      }
    end

    let(:coin_metadata) do
      {
        number_in_accession: "coin-accession",
        analysis: "coin-analysis",
        counter_stamp: "coin-counter-stamp",
        depositor: "coin-depositor",
        die_axis: "coin-die-axis",
        find_date: "coin-find-date",
        find_description: "coin-find-description",
        find_feature: "coin-find-feature",
        find_locus: "coin-find-locus",
        find_number: "coin-find-number",
        private_note: "coin-private-note",
        replaces: "coin-replaces",
        size: "coin-size",
        technique: "coin-technique",
        weight: "coin-weight"
      }
    end

    before do
      issue
      persister.save(resource: coin) # re-save coin to index parent (normally happens in change_set_persister)
    end

    it "finds coins by issue metadata fields" do
      issue_metadata.values.each do |val|
        get :index, params: {q: val}
        expect(assigns(:document_list)).not_to be_empty
        expect(assigns(:document_list).map(&:id)).to include(coin.id.to_s)
      end
    end

    it "finds coins by coin metadata fields" do
      coin_metadata.values.each do |val|
        get :index, params: {q: val}
        expect(assigns(:document_list)).not_to be_empty
        expect(assigns(:document_list).map(&:id)).to include(coin.id.to_s)
      end
    end
  end

  describe "#pdf" do
    let(:resources) { [resource] }
    before do
      persister.save_all(resources: resources)
    end

    context "when the resource was ingested from a pdf" do
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, member_ids: [file_set.id]) }
      let(:file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: [file_meta]) }
      let(:file_meta) { FileMetadata.new(id: "1234", use: Valkyrie::Vocab::PCDMUse.OriginalFile, mime_type: "application/pdf") }
      let(:resources) { [resource, file_set] }

      it "downloads the original pdf" do
        get :pdf, params: {solr_document_id: resource.id}
        expect(response).to redirect_to "http://test.host/downloads/#{file_set.id}/file/1234"
      end
    end

    context "when the resource can generate a pdf" do
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource) }

      it "redirects to the pdf" do
        get :pdf, params: {solr_document_id: resource.id}
        expect(response).to redirect_to "http://test.host/concern/scanned_resources/#{resource.id}/pdf"
      end
    end
    context "when the resource can't generate a pdf" do
      let(:resource) { FactoryBot.create_for_repository(:collection) }

      it "redirects to the show page" do
        get :pdf, params: {solr_document_id: resource.id.to_s}
        expect(response).to redirect_to "http://test.host/catalog/#{resource.id}"
      end
    end
  end
end
