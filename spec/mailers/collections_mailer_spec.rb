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
      expect(email.body.to_s).to eq expected_body(ids: [r1.id, r2.id, r3.id])
      email.deliver
      expect(ActionMailer::Base.deliveries).not_to be_empty
    end

    it "does nothing when there's no owner" do
      collection = FactoryBot.create_for_repository(:collection, title: "The Important Person's Things", slug: "important-persons-things", owners: [])
      FactoryBot.create_for_repository(:scanned_resource, title: "Historically Significant Resource", state: "pending", member_of_collection_ids: [collection.id])
      email = described_class.with(collection: collection).owner_report
      email.deliver
      expect(ActionMailer::Base.deliveries).to be_empty
    end

    it "does nothing when all resources are complete" do
      collection = FactoryBot.create_for_repository(:collection, title: "The Important Person's Things", slug: "important-persons-things", owners: [user.uid, user2.uid])
      FactoryBot.create_for_repository(:scanned_resource, title: "Historically Significant Resource", state: "complete", member_of_collection_ids: [collection.id])
      email = described_class.with(collection: collection).owner_report
      email.deliver
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  def expected_body(ids:)
    <<-FIXTURE
<!DOCTYPE html>
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <style>
      /* Email styles need to be inline */
    </style>
  </head>

  <body>
    <!DOCTYPE html>
<html>
  <head>
    <meta content='text/html; charset=UTF-8' http-equiv='Content-Type' />
  </head>
  <body>
    <h2>Weekly collection report for The Important Person&#39;s Things</h2>
    <p>Resources in workflow state "pending"</p>
    <ul>
      <li>
        <a href="http://www.example.com/catalog/#{ids.shift}">Historically Significant Resource</a>
      </li>
      <li>
        <a href="http://www.example.com/catalog/#{ids.shift}">Culturally Significant Resource</a>
      </li>
    </ul>
    <p>Resources in workflow state "final review"</p>
    <ul>
      <li>
        <a href="http://www.example.com/catalog/#{ids.shift}">Pretty Resource</a>
      </li>
    </ul>
  </body>
</html>

  </body>
</html>
FIXTURE
  end
end
