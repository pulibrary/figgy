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
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "individuals", notice_type: "senior_thesis") }
    let(:id) { resource.id }
    let(:query_string) { %|{ resource(id: "#{id}") { viewingHint } }| }

    context "when given a scanned resource" do
      it "returns a viewing hint" do
        # calling `result` executes the query
        expect(result["data"]["resource"]["viewingHint"]).to eq("individuals")
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
    end

    context "when given a file set" do
      let(:resource) { FactoryBot.create_for_repository(:file_set, viewing_hint: "individuals") }
      it "works" do
        expect(result["data"]["resource"]["viewingHint"]).to eq "individuals"
      end
    end
  end
end
