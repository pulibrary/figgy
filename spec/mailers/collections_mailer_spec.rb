# frozen_string_literal: true

require "rails_helper"

RSpec.describe CollectionsMailer, type: :mailer do
  describe "owner_report" do
    let(:user) { FactoryBot.create(:admin) }
    let(:user2) { FactoryBot.create(:staff) }
    it "works" do
      collection = FactoryBot.create_for_repository(:collection, title: "The Important Person's Things", slug: "important-persons-things", owners: [user.uid, user2.uid])
      r1 = FactoryBot.create_for_repository(:scanned_resource, title: "Historically Significant Resource", state: "pending", member_of_collection_ids: [collection.id])
      r2 = FactoryBot.create_for_repository(:scanned_resource, title: "Culturally Significant Resource", state: "pending", member_of_collection_ids: [collection.id])
      r3 = FactoryBot.create_for_repository(:scanned_resource, title: "Pretty Resource", state: "final review", member_of_collection_ids: [collection.id])
      FactoryBot.create(:scanned_resource, title: "Curious Resource", state: "complete", member_of_collection_ids: [collection.id])

      # Create the email and store it for further assertions
      email = described_class.with(collection: collection).owner_report

      # Test the body of the sent email contains what we expect it to
      expect(email.from).to contain_exactly "no-reply@www.example.com"
      expect(email.to).to contain_exactly user.email, user2.email
      expect(email.subject).to eq "Weekly collection report for The Important Person's Things"
      # the final review section contains exactly the one final review object
      expect(email.body.to_s).to include expected_final(id: r3.id)
      # the pending section is there, as are its two objects.
      # since they're not in the final review section they must be in the right place
      # thus the spec is less vulnerable to order fluctations
      expect(email.body.to_s).to include "<p>2 Resource(s) in workflow state \"pending\"</p>"
      expect(email.body.to_s).to include expected_pending(resource: r1)
      expect(email.body.to_s).to include expected_pending(resource: r2)
      expect(email.body.to_s).to include expected_collection(collection: collection)
      email.deliver
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    context "when there's no owner" do
      it "does nothing" do
        collection = FactoryBot.create_for_repository(:collection, title: "The Important Person's Things", slug: "important-persons-things", owners: [])
        FactoryBot.create_for_repository(:scanned_resource, title: "Historically Significant Resource", state: "pending", member_of_collection_ids: [collection.id])
        email = described_class.with(collection: collection).owner_report
        email.deliver
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when all resources are complete" do
      it "does nothing" do
        collection = FactoryBot.create_for_repository(:collection, title: "The Important Person's Things", slug: "important-persons-things", owners: [user.uid, user2.uid])
        FactoryBot.create_for_repository(:scanned_resource, title: "Historically Significant Resource", state: "complete", member_of_collection_ids: [collection.id])
        email = described_class.with(collection: collection).owner_report
        email.deliver
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when there's an owner who is not in the database" do
      let(:user2) { "some_rando" }
      it "sends the report to the owner it could find" do
        collection = FactoryBot.create_for_repository(:collection, title: "The Important Person's Things", slug: "important-persons-things", owners: [user.uid, user2])
        FactoryBot.create_for_repository(:scanned_resource, title: "Historically Significant Resource", state: "pending", member_of_collection_ids: [collection.id])
        email = described_class.with(collection: collection).owner_report
        expect(email.to).to contain_exactly user.email
      end
    end
  end

  def expected_final(id:)
    <<-FIXTURE
    <p>1 Resource(s) in workflow state "final review"</p>
    <ul>
      <li>
        <a href="http://www.example.com/catalog/#{id}">Pretty Resource</a>
      </li>
    </ul>
    FIXTURE
  end

  def expected_pending(resource:)
    <<-FIXTURE
      <li>
        <a href="http://www.example.com/catalog/#{resource.id}">#{resource.title.first}</a>
      </li>
    FIXTURE
  end

  def expected_collection(collection:)
    "<p>You received this email because you are a collection owner of <a href=\"http://www.example.com/catalog/#{collection.id}\">#{collection.title.first}</a>"
  end
end
