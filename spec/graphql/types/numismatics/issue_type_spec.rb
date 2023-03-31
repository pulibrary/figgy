# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::Numismatics::IssueType do
  describe "fields" do
    it "has startPage" do
      expect(described_class).to have_field(:startPage)
    end
  end

  subject(:type) { make_graphql_object(described_class, numismatic_issue, { ability: ability }) }
  let(:numismatic_issue) do
    FactoryBot.create_for_repository(
      :numismatic_issue,
      viewing_hint: "individuals",
      viewing_direction: "left-to-right"
    )
  end
  let(:ability) { instance_double(Ability, can?: true) }

  describe "class methods" do
    subject { described_class }

    # Note! These field names use a javascript-y camel-case variable style
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:viewingDirection).of_type(Types::ViewingDirectionEnum) }
    it { is_expected.to have_field(:label).of_type(String) }
    it { is_expected.to have_field(:members) }
    it { is_expected.to have_field(:manifestUrl).of_type(String) }
  end

  describe "#viewing_hint" do
    it "returns a singular value" do
      expect(type.viewing_hint).to eq "individuals"
    end
  end

  describe "#viewing_direction" do
    it "returns a singular value" do
      expect(type.viewing_direction).to eq "left-to-right"
    end
  end

  describe "#manifest_url" do
    it "links to the manifest URL" do
      expect(type.manifest_url).to eq "http://www.example.com/concern/numismatics/issues/#{numismatic_issue.id}/manifest"
    end
  end

  describe "#thumbnail" do
    context "when a thumbnail is not set" do
      it "returns nil" do
        expect(type.thumbnail).to eq nil
      end
    end
    context "when there is a child coin" do
      let(:numismatic_issue) do
        FactoryBot.create_for_repository(:numismatic_issue, thumbnail_id: coin.id)
      end
      let(:coin) do
        FactoryBot.create_for_repository(:coin, thumbnail_id: file_set.id)
      end
      let(:file_set) do
        FactoryBot.create_for_repository(:file_set)
      end
      it "returns a thumbnail service url/image for the file set, but ID of the coin" do
        expect(type.thumbnail).to eq(
          iiif_service_url: "http://www.example.com/image-service/#{file_set.id}",
          thumbnail_url: "http://www.example.com/image-service/#{file_set.id}/full/!200,150/0/default.jpg",
          id: coin.id.to_s
        )
      end
    end
  end

  describe "#start_page" do
    let(:numismatic_issue) do
      FactoryBot.create_for_repository(:numismatic_issue, start_canvas: file_set_id)
    end
    let(:file_set_id) { "i_am_a_file_set" }
    it "returns a resource's first start_canvas" do
      expect(type.start_page).to eq file_set_id.to_s
    end
  end

  describe "#label" do
    it "maps to a resource's title" do
      expect(type.label).to eq "Issue: #{numismatic_issue.issue_number}"
    end
  end

  describe "#url" do
    it "links to the catalog URL" do
      expect(type.url).to eq "http://www.example.com/catalog/#{numismatic_issue.id}"
    end
  end

  describe "#members" do
    it "returns all members" do
      child_resource1 = FactoryBot.create_for_repository(:coin)
      child_resource2 = FactoryBot.create_for_repository(:coin)
      numismatic_issue = FactoryBot.create_for_repository(:numismatic_issue, member_ids: [child_resource1.id, child_resource2.id])

      type = make_graphql_object(described_class, numismatic_issue)

      expect(type.members.map(&:id)).to eq [child_resource1.id, child_resource2.id]
    end
  end
end
