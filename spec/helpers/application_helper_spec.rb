# frozen_string_literal: true
require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#facet_search_url" do
    it "provides a link to a search result page faceted by collection" do
      field = "member_of_collection_titles_ssim"
      value = "The Sid Lapidus '59 Collection on Liberty and the American Revolution"
      result = "/?f%5Bmember_of_collection_titles_ssim%5D%5B%5D=The+Sid+Lapidus+%2759+Collection+on+Liberty+and+the+American+Revolution"
      expect(helper.facet_search_url(field: field, value: value)).to eq result
    end
  end

  describe "#resource_attribute_value" do
    context "with a regular attribute value" do
      it "returns the value" do
        expect(helper.resource_attribute_value(:description, "A description")).to eq("A description")
      end
    end

    context "with a member_of_collections attribute" do
      let(:title) { "My Collection" }
      let(:collection) { FactoryBot.create_for_repository(:collection, title: title) }

      it "returns a link to the collection" do
        value = helper.resource_attribute_value(:member_of_collections, collection.decorate)
        expect(value).to include("href", collection.id.to_s, title)
      end
    end

    context "with an authorized_link attribute" do
      let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
      let(:resource) do
        res = Playlist.new
        cs = PlaylistChangeSet.new(res)
        cs.prepopulate!
        cs.validate(label: ["my playlist"], state: "complete")
        change_set_persister.save(change_set: cs)
      end
      let(:decorated) { resource.decorate }
      let(:value) { helper.resource_attribute_value(:authorized_link, decorated.authorized_link) }

      before do
        allow(helper).to receive(:resource).and_return(resource)
      end

      it "generates a link with an authorization token to the Resource" do
        expect(value).to eq "<a href=\"/catalog/#{resource.id}?auth_token=#{resource.auth_token}\">http://test.host/catalog/#{resource.id}?auth_token=#{resource.auth_token}</a>"
      end
    end
  end
end
