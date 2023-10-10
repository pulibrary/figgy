# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::UpdateCloudFilePermissions do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }
  let(:file_path) { "ab/12/display_vector.pmtiles" }
  let(:file_id) { "cloud-geo-derivatives-shrine://#{file_path}" }
  let(:cloud_metadata) { FactoryBot.build(:cloud_vector_derivative, file_identifiers: [file_id]) }
  let(:file_set) do
    FactoryBot.create_for_repository(:file_set, file_metadata: [
                                       FactoryBot.build(:vector_original),
                                       cloud_metadata
                                     ])
  end

  let(:vector_resource) { FactoryBot.create_for_repository(:open_vector_resource, member_ids: [file_set.id]) }

  let(:change_set) { ChangeSet.for(vector_resource) }

  describe "#run" do
    let(:client) { instance_double(Aws::S3::Client) }

    before do
      allow(Aws::S3::Client).to receive(:new).and_return(client)
      allow(client).to receive(:put_object_acl)
    end

    context "with an open resource that has a changed authenticated visibility" do
      it "updates cloud file permissions" do
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        hook.run

        expect(client).to have_received(:put_object_acl).with(acl: "public-read", bucket: "test-geo", key: file_path)
      end
    end

    context "with an authenticated resource that has a changed open visiblity value" do
      let(:vector_resource) { FactoryBot.create_for_repository(:campus_only_vector_resource, member_ids: [file_set.id]) }

      it "updates cloud file permissions" do
        change_set.validate(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC)
        hook.run

        expect(client).to have_received(:put_object_acl).with(acl: "private", bucket: "test-geo", key: file_path)
      end
    end

    context "with a resource that does not have a changed visiblity value" do
      it "does not update cloud file permissions" do
        hook.run

        expect(client).not_to have_received(:put_object_acl)
      end
    end
  end
end
