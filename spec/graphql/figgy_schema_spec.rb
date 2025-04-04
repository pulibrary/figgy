# frozen_string_literal: true
require "rails_helper"

RSpec.describe FiggySchema do
  # You can override `context` or `variables` in
  # more specific scopes
  let(:context) { { ability: instance_double(Ability, can?: true), change_set_persister: GraphqlController.change_set_persister } }
  let(:variables) { {} }
  # Call `result` to execute the query
  let(:result) do
    res = described_class.execute(
      query_string,
      context: context,
      variables: variables
    )
    # Print any errors
    pp res if res["errors"]
    res
  end

  describe "resource query" do
    # provide a query string for `result`
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "individuals", notice_type: "senior_thesis", member_ids: [member.id]) }
    let(:member) { FactoryBot.create_for_repository(:file_set) }
    let(:id) { resource.id }
    let(:query_string) { %|{ resource(id: "#{id}") { viewingHint } }| }

    context "when given a scanned resource" do
      it "returns a viewing hint" do
        # calling `result` executes the query
        expect(result["data"]["resource"]["viewingHint"]).to eq("individuals")
      end
    end

    context "when requesting member_ids" do
      let(:query_string) { %|{ resource(id: "#{id}") { memberIds } }| }
      it "returns it" do
        expect(result["data"]["resource"]["memberIds"]).to eq([member.id.to_s])
      end
    end

    context "when requesting an embed" do
      let(:query_string) { %|{ resource(id: "#{id}") { embed { type, content, status } } }| }
      it "returns it" do
        expect(result["errors"]).to be_blank
        expect(result["data"]["resource"]["embed"]).to eq(
          {
            "type" => "html",
            "content" => "<iframe allowfullscreen=\"true\" id=\"uv_iframe\" src=\"http://www.example.com/viewer#?manifest=http://www.example.com/concern/scanned_resources/#{id}/manifest\"></iframe>",
            "status" => "authorized"
          }
        )
      end
      context "for a video item" do
        with_queue_adapter :inline
        let(:resource) { FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions) }
        let(:query_string) { %|{ resource(id: "#{id}") { embed { mediaType } } }| }
        it "returns the media_type as a video" do
          expect(result["errors"]).to be_blank
          expect(result["data"]["resource"]["embed"]).to eq(
            {
              "mediaType" => "Video"
            }
          )
        end
      end
    end

    context "when requesting a notice" do
      let(:query_string) { %|{ resource(id: "#{id}") { notice { heading, acceptLabel, textHtml } } }| }
      it "returns a notice heading and text" do
        expect(result["errors"]).to be_blank
        notice = result["data"]["resource"]["notice"]

        expect(notice.keys).to contain_exactly "heading", "acceptLabel", "textHtml"
        expect(notice["heading"]).to eq "Terms and Conditions for Using Princeton University Senior Theses"
        expect(notice["acceptLabel"]).to eq "Accept"
        expect(notice["textHtml"]).to start_with "<p>The Princeton University Senior Theses"
      end
      context "for a content_warning resource" do
        let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "C1372_c47202-68234", import_metadata: true) }
        it "creates a specific notice" do
          stub_findingaid(pulfa_id: "C1372_c47202-68234")

          expect(result["errors"]).to be_blank
          notice = result["data"]["resource"]["notice"]

          expect(notice["heading"]).to eq "Content Warning"
          expect(notice["acceptLabel"]).to eq "View Content"
          expect(notice["textHtml"]).to eq "<p>The \"Revolution in China\" album contains photographs of dead bodies.</p> " \
            "<p>For more information, please see the PUL statement on Responsible Collection Description: " \
            '<a href="https://library.princeton.edu/about/responsible-collection-description" target="_blank">https://library.princeton.edu/about/responsible-collection-description</a></p>'
        end
      end
      context "for a resource with both an imported and a local content warning" do
        let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "C1372_c47202-68234", content_warning: "Bad stuff in here.", import_metadata: true) }
        it "prioritizes the imported warning" do
          stub_findingaid(pulfa_id: "C1372_c47202-68234")

          expect(result["errors"]).to be_blank
          notice = result["data"]["resource"]["notice"]

          expect(notice["heading"]).to eq "Content Warning"
          expect(notice["acceptLabel"]).to eq "View Content"
          expect(notice["textHtml"]).to eq "<p>The \"Revolution in China\" album contains photographs of dead bodies.</p> " \
            "<p>For more information, please see the PUL statement on Responsible Collection Description: " \
            '<a href="https://library.princeton.edu/about/responsible-collection-description" target="_blank">https://library.princeton.edu/about/responsible-collection-description</a></p>'
        end
      end
      context "for a local content_warning bibliographic resource" do
        let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "991234563506421", import_metadata: true, content_warning: "There's harmful content here.") }
        it "creates a specific notice" do
          stub_catalog(bib_id: "991234563506421")

          expect(result["errors"]).to be_blank
          notice = result["data"]["resource"]["notice"]

          expect(notice["heading"]).to eq "Content Warning"
          expect(notice["acceptLabel"]).to eq "View Content"
          expect(notice["textHtml"]).to eq "<p>There's harmful content here.</p> " \
            "<p>For more information, please see the PUL statement on Responsible Collection Description: " \
            '<a href="https://library.princeton.edu/about/responsible-collection-description" target="_blank">https://library.princeton.edu/about/responsible-collection-description</a></p>'
        end
      end
      context "for an ephemera_folder with a content_warning" do
        let(:resource) { FactoryBot.create_for_repository(:ephemera_folder, content_warning: "There's harmful content here.") }
        it "creates a specific notice" do
          expect(result["errors"]).to be_blank
          notice = result["data"]["resource"]["notice"]

          expect(notice["heading"]).to eq "Content Warning"
          expect(notice["acceptLabel"]).to eq "View Content"
          expect(notice["textHtml"]).to eq "<p>There's harmful content here.</p> " \
            "<p>For more information, please see the PUL statement on Responsible Collection Description: " \
            '<a href="https://library.princeton.edu/about/responsible-collection-description" target="_blank">https://library.princeton.edu/about/responsible-collection-description</a></p>'
        end
      end
    end

    context "when given a file set" do
      let(:resource) { FactoryBot.create_for_repository(:file_set, viewing_hint: "individuals") }
      it "works" do
        expect(result["data"]["resource"]["viewingHint"]).to eq "individuals"
      end
    end
  end
end
