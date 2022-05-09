# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkUpdateMailer, type: :mailer do
  describe "update_status" do
    let(:user) { FactoryBot.create(:admin) }
    let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, state: "pending") }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, state: "pending") }
    let(:ids) { [resource1.id, resource2.id] }
    let(:search_params) { { f: { member_of_collection_titles_ssim: ["The Important Person's Things"], state_ssim: ["pending"] }, q: "significant" } }
    let(:change_set) { ChangeSet.for(resource1) }

    before do
      allow(ChangeSet).to receive(:for).and_return(change_set)
      allow(change_set).to receive(:valid?).and_return(false)
    end

    context "works" do
      it "when bulk update succeeds" do
        time = Time.current.to_s
        email = described_class.with(email: user.email, ids: ids, time: time, search_params: search_params).update_status

        expect(email.from).to contain_exactly "no-reply@www.example.com"
        expect(email.to).to contain_exactly user.email
        expect(email.subject).to eq "Bulk update status for batch initiated on #{time}"
        expect(email.body.to_s).to include "Bulk update successful for #{ids.length} Resource(s) in batch."
        expect(email.body.to_s).to include expected_search_params(search_params: search_params)
        expect(email.body.to_s).to include expected_ids(ids: ids)

        email.deliver
        expect(ActionMailer::Base.deliveries).not_to be_empty
      end

      it "when bulk update fails" do
        time = Time.current.to_s
        email = described_class.with(email: user.email, ids: ids, resource_id: resource1.id, time: time, search_params: search_params).update_status

        expect(email.from).to contain_exactly "no-reply@www.example.com"
        expect(email.to).to contain_exactly user.email
        expect(email.subject).to eq "Bulk update status for batch initiated on #{time}"
        expect(email.body.to_s).to include "Bulk update failed due to invalid parameters on Resource with ID <a href=\"http://www.example.com/catalog/#{resource1.id}\">#{resource1.id}</a>"
        expect(email.body.to_s).to include expected_search_params(search_params: search_params)
        expect(email.body.to_s).to include expected_ids(ids: ids)

        email.deliver
        expect(ActionMailer::Base.deliveries).not_to be_empty
      end
    end
  end

  def expected_search_params(search_params:)
    <<-FIXTURE
    <p>
      You received this email because you initiated a bulk update with the following search parameters:
    </p>
    <ul>
      <li>Query: #{search_params[:q]}</li>
      <li>Facets: #{search_params[:f]}</li>
    </ul>
    FIXTURE
  end

  def expected_ids(ids:)
    <<-FIXTURE
    <p>And for these Resources(s):</p>
    <ul>
        <li><a href=\"http://www.example.com/catalog/#{ids[0]}\">#{ids[0]}</a></li>
        <li><a href=\"http://www.example.com/catalog/#{ids[1]}\">#{ids[1]}</a></li>
    </ul>
    FIXTURE
  end
end
