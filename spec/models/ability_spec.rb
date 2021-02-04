# frozen_string_literal: true
require "rails_helper"
require "cancan/matchers"

describe Ability do
  subject { described_class.new(current_user) }
  let(:page_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:page_file_2) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:page_file_3) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:audio_file) { fixture_file_upload("files/audio_file.wav", "audio/x-wav") }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    allow(CDL::EligibleItemService).to receive(:item_ids)
  end

  let(:open_scanned_resource) do
    FactoryBot.create_for_repository(:complete_open_scanned_resource, user: creating_user, title: "Open", files: [page_file])
  end

  let(:open_file) { open_scanned_resource.decorate.members.first }

  let(:open_file_set) do
    query_service.find_by(id: open_scanned_resource.member_ids.first)
  end

  let(:no_public_download_open_scanned_resource) do
    FactoryBot.create_for_repository(:complete_open_scanned_resource, user: creating_user, title: "Open", downloadable: "none", files: [page_file_3])
  end

  let(:no_public_download_open_file) { no_public_download_open_scanned_resource.decorate.members.first }

  let(:closed_file_set) do
    query_service.find_by(id: private_scanned_resource.member_ids.first)
  end

  let(:private_scanned_resource) do
    FactoryBot.create_for_repository(:complete_private_scanned_resource, title: "Private", user: creating_user, files: [page_file_2])
  end

  let(:private_cdl_scanned_resource) do
    stub_bibdata(bib_id: "123456")
    resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, title: "Private", source_metadata_identifier: "123456", user: creating_user, files: [page_file_2])
    FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: resource.id,
      charged_items: [
        CDL::ChargedItem.new(item_id: "1234", netid: current_user&.uid || "rando", expiration_time: Time.current + 3.hours)
      ]
    )
    allow(CDL::EligibleItemService).to receive(:item_ids).with(source_metadata_identifier: "123456").and_return(["1"])
    resource
  end

  let(:private_cdl_mvw_scanned_resource) do
    stub_bibdata(bib_id: "123456")
    volume = FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [page_file_2])
    mvw_resource = FactoryBot.create_for_repository(:complete_private_scanned_resource,
                                                    title: "Private",
                                                    source_metadata_identifier: "123456",
                                                    user: creating_user,
                                                    member_ids: [volume.id],
                                                    run_callbacks: true)
    FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: mvw_resource.id,
      charged_items: [
        CDL::ChargedItem.new(item_id: "1234", netid: current_user&.uid || "rando", expiration_time: Time.current + 3.hours)
      ]
    )
    allow(CDL::EligibleItemService).to receive(:item_ids).with(source_metadata_identifier: "123456").and_return(["1"])
    mvw_resource
  end

  let(:expired_private_cdl_scanned_resource) do
    stub_bibdata(bib_id: "123456")
    resource = FactoryBot.create_for_repository(:complete_private_scanned_resource, title: "Private", source_metadata_identifier: "123456", user: creating_user, files: [page_file_2])
    FactoryBot.create_for_repository(
      :resource_charge_list,
      resource_id: resource.id,
      charged_items: [
        CDL::ChargedItem.new(item_id: "1234", netid: current_user&.uid || "rando", expiration_time: Time.current - 3.hours)
      ]
    )
    allow(CDL::EligibleItemService).to receive(:item_ids).with(source_metadata_identifier: "123456").and_return(["1"])
    resource
  end

  let(:campus_only_scanned_resource) do
    FactoryBot.create_for_repository(:complete_campus_only_scanned_resource, title: "Campus Only", user: creating_user)
  end

  let(:reading_room_scanned_resource) do
    FactoryBot.create_for_repository(:reading_room_scanned_resource, title: "Reading Room", user: creating_user)
  end

  let(:campus_ip_scanned_resource) do
    FactoryBot.create_for_repository(:campus_ip_scanned_resource, title: "On Campus", user: creating_user)
  end

  let(:pending_scanned_resource) do
    FactoryBot.create_for_repository(:pending_scanned_resource, title: "Pending", user: creating_user)
  end

  let(:metadata_review_scanned_resource) do
    FactoryBot.create_for_repository(:metadata_review_scanned_resource, user: creating_user)
  end

  let(:final_review_scanned_resource) do
    FactoryBot.create_for_repository(:final_review_scanned_resource, user: creating_user)
  end

  let(:complete_scanned_resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource, user: other_staff_user, identifier: ["ark:/99999/fk4445wg45"])
  end

  let(:takedown_scanned_resource) do
    FactoryBot.create_for_repository(:takedown_scanned_resource, user: other_staff_user, identifier: ["ark:/99999/fk4445wg45"])
  end

  let(:flagged_scanned_resource) do
    FactoryBot.create_for_repository(:flagged_scanned_resource, user: other_staff_user, identifier: ["ark:/99999/fk4445wg45"])
  end

  let(:staff_scanned_resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource, user: staff_user, identifier: ["ark:/99999/fk4445wg45"], files: [file])
  end

  let(:complete_playlist) do
    FactoryBot.create_for_repository(:complete_playlist, user: creating_user, recording: complete_recording)
  end

  let(:complete_recording) do
    FactoryBot.create_for_repository(:complete_recording, user: creating_user, files: [audio_file])
  end

  let(:token_downloadable_audio_file) { complete_playlist.decorate.file_sets.first }

  let(:file) { fixture_file_upload("files/example.tif") }
  let(:other_staff_scanned_resource) do
    FactoryBot.create_for_repository(:complete_scanned_resource, user: other_staff_user, identifier: ["ark:/99999/fk4445wg45"], files: [file])
  end

  let(:staff_file) { staff_scanned_resource.decorate.members.first }
  let(:other_staff_file) { other_staff_scanned_resource.decorate.members.first }
  let(:admin_file) { FactoryBot.build(:file_set, user: admin_user) }

  let(:contributor_ephemera_project) do
    FactoryBot.create_for_repository(:ephemera_project, member_ids: [contributor_ephemera_folder.id, contributor_ephemera_box.id], contributor_uids: [current_user&.uid])
  end
  let(:contributor_ephemera_folder) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:contributor_ephemera_box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: contributor_ephemera_folder_in_box.id) }
  let(:contributor_ephemera_folder_in_box) { FactoryBot.create_for_repository(:ephemera_folder) }

  let(:non_contributor_ephemera_project) do
    FactoryBot.create_for_repository(:ephemera_project, member_ids: [contributor_ephemera_folder.id, contributor_ephemera_box.id])
  end
  let(:non_contributor_ephemera_folder) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:non_contributor_ephemera_box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: contributor_ephemera_folder_in_box.id) }
  let(:non_contributor_ephemera_folder_in_box) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:restricted_viewer_collection) do
    # There's no current_user for anonymous user tests, but we need a netid in
    # `restricted_viewers`, so if there's no current_user fill it with "rando"
    FactoryBot.create_for_repository(:collection, restricted_viewers: [current_user&.uid || "rando"])
  end
  let(:ineligible_restricted_viewer_collection) do
    FactoryBot.create_for_repository(:collection, restricted_viewers: ["rando"])
  end
  let(:ineligible_restricted_viewer_scanned_resource) do
    FactoryBot.create_for_repository(:reading_room_scanned_resource, files: [page_file_2], member_of_collection_ids: ineligible_restricted_viewer_collection.id)
  end
  let(:reading_room_collection_restricted_viewer_scanned_resource) do
    FactoryBot.create_for_repository(:reading_room_scanned_resource, files: [page_file_2], member_of_collection_ids: [restricted_viewer_collection.id])
  end
  let(:private_collection_restricted_viewer_scanned_resource) do
    FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [page_file_2], member_of_collection_ids: restricted_viewer_collection.id)
  end

  let(:ocr_request) { FactoryBot.create(:ocr_request) }

  let(:admin_user) { FactoryBot.create(:admin) }
  let(:staff_user) { FactoryBot.create(:staff) }
  let(:other_staff_user) { FactoryBot.create(:staff) }
  let(:netid_user) { FactoryBot.create(:user) }
  let(:reading_room_user) { FactoryBot.create(:reading_room_user) }
  let(:role) { Role.where(name: "admin").first_or_create }

  describe "as an admin" do
    let(:admin_user) { FactoryBot.create(:admin) }
    let(:creating_user) { staff_user }
    let(:current_user) { admin_user }

    it {
      is_expected.to be_able_to(:create, ScannedResource.new)
      is_expected.to be_able_to(:create, FileSet.new)
      is_expected.to be_able_to(:create, OcrRequest.new)
      is_expected.to be_able_to(:read, open_scanned_resource)
      is_expected.to be_able_to(:read, private_scanned_resource)
      is_expected.to be_able_to(:read, takedown_scanned_resource)
      is_expected.to be_able_to(:read, flagged_scanned_resource)
      is_expected.to be_able_to(:read, reading_room_scanned_resource)
      is_expected.to be_able_to(:read, campus_ip_scanned_resource)
      is_expected.to be_able_to(:read, contributor_ephemera_project)
      is_expected.to be_able_to(:read, contributor_ephemera_folder)
      is_expected.to be_able_to(:read, ocr_request)
      is_expected.to be_able_to(:pdf, open_scanned_resource)
      is_expected.to be_able_to(:color_pdf, open_scanned_resource)
      is_expected.to be_able_to(:edit, open_scanned_resource)
      is_expected.to be_able_to(:edit, private_scanned_resource)
      is_expected.to be_able_to(:edit, takedown_scanned_resource)
      is_expected.to be_able_to(:edit, flagged_scanned_resource)
      is_expected.to be_able_to(:edit, contributor_ephemera_project)
      is_expected.to be_able_to(:edit, contributor_ephemera_folder)
      is_expected.to be_able_to(:edit, ocr_request)
      is_expected.to be_able_to(:file_manager, open_scanned_resource)
      is_expected.to be_able_to(:update, open_scanned_resource)
      is_expected.to be_able_to(:update, private_scanned_resource)
      is_expected.to be_able_to(:update, takedown_scanned_resource)
      is_expected.to be_able_to(:update, flagged_scanned_resource)
      is_expected.to be_able_to(:update, contributor_ephemera_project)
      is_expected.to be_able_to(:update, contributor_ephemera_folder)
      is_expected.to be_able_to(:update, ocr_request)
      is_expected.to be_able_to(:destroy, open_scanned_resource)
      is_expected.to be_able_to(:destroy, private_scanned_resource)
      is_expected.to be_able_to(:destroy, takedown_scanned_resource)
      is_expected.to be_able_to(:destroy, flagged_scanned_resource)
      is_expected.to be_able_to(:destroy, contributor_ephemera_project)
      is_expected.to be_able_to(:destroy, contributor_ephemera_folder)
      is_expected.to be_able_to(:destroy, ocr_request)
      is_expected.to be_able_to(:manifest, open_scanned_resource)
      is_expected.to be_able_to(:manifest, pending_scanned_resource)
      is_expected.to be_able_to(:manifest, reading_room_scanned_resource)
      is_expected.to be_able_to(:manifest, campus_ip_scanned_resource)
      is_expected.to be_able_to(:discover, open_scanned_resource)
      is_expected.to be_able_to(:discover, pending_scanned_resource)
      is_expected.to be_able_to(:discover, reading_room_scanned_resource)
      is_expected.to be_able_to(:discover, campus_ip_scanned_resource)
      is_expected.to be_able_to(:read, :graphql)
      is_expected.to be_able_to(:download, no_public_download_open_file)
      is_expected.to be_able_to(:download, token_downloadable_audio_file)
    }

    context "when read-only mode is on" do
      before { allow(Figgy).to receive(:read_only_mode).and_return(true) }

      it {
        is_expected.not_to be_able_to(:create, ScannedResource.new)
        is_expected.not_to be_able_to(:create, FileSet.new)
        is_expected.not_to be_able_to(:create, OcrRequest.new)
        is_expected.to be_able_to(:read, open_scanned_resource)
        is_expected.to be_able_to(:read, private_scanned_resource)
        is_expected.to be_able_to(:read, takedown_scanned_resource)
        is_expected.to be_able_to(:read, flagged_scanned_resource)
        is_expected.to be_able_to(:read, flagged_scanned_resource)
        is_expected.to be_able_to(:read, ocr_request)
        is_expected.not_to be_able_to(:pdf, open_scanned_resource)
        is_expected.not_to be_able_to(:color_pdf, open_scanned_resource)
        is_expected.not_to be_able_to(:edit, open_scanned_resource)
        is_expected.not_to be_able_to(:edit, private_scanned_resource)
        is_expected.not_to be_able_to(:edit, takedown_scanned_resource)
        is_expected.not_to be_able_to(:edit, flagged_scanned_resource)
        is_expected.not_to be_able_to(:edit, ocr_request)
        is_expected.not_to be_able_to(:file_manager, open_scanned_resource)
        is_expected.not_to be_able_to(:update, open_scanned_resource)
        is_expected.not_to be_able_to(:update, private_scanned_resource)
        is_expected.not_to be_able_to(:update, takedown_scanned_resource)
        is_expected.not_to be_able_to(:update, flagged_scanned_resource)
        is_expected.not_to be_able_to(:update, ocr_request)
        is_expected.not_to be_able_to(:destroy, open_scanned_resource)
        is_expected.not_to be_able_to(:destroy, private_scanned_resource)
        is_expected.not_to be_able_to(:destroy, takedown_scanned_resource)
        is_expected.not_to be_able_to(:destroy, flagged_scanned_resource)
        is_expected.not_to be_able_to(:destroy, ocr_request)
        is_expected.to be_able_to(:manifest, open_scanned_resource)
        is_expected.to be_able_to(:manifest, pending_scanned_resource)
        is_expected.to be_able_to(:discover, open_scanned_resource)
        is_expected.to be_able_to(:discover, pending_scanned_resource)
        is_expected.to be_able_to(:discover, reading_room_scanned_resource)
        is_expected.to be_able_to(:discover, campus_ip_scanned_resource)
        is_expected.to be_able_to(:read, :graphql)
      }
    end
  end

  describe "as a staff" do
    let(:creating_user) { other_staff_user }
    let(:current_user) { staff_user }

    it {
      is_expected.to be_able_to(:create, ScannedResource.new)
      is_expected.to be_able_to(:create, FileSet.new)
      is_expected.to be_able_to(:create, OcrRequest.new)
      is_expected.to be_able_to(:read, open_scanned_resource)
      is_expected.to be_able_to(:read, private_scanned_resource)
      is_expected.to be_able_to(:read, takedown_scanned_resource)
      is_expected.to be_able_to(:read, flagged_scanned_resource)
      is_expected.to be_able_to(:read, ocr_request)
      is_expected.to be_able_to(:pdf, open_scanned_resource)
      is_expected.to be_able_to(:color_pdf, open_scanned_resource)
      is_expected.to be_able_to(:edit, open_scanned_resource)
      is_expected.to be_able_to(:edit, private_scanned_resource)
      is_expected.to be_able_to(:edit, takedown_scanned_resource)
      is_expected.to be_able_to(:edit, flagged_scanned_resource)
      is_expected.to be_able_to(:edit, ocr_request)
      is_expected.to be_able_to(:file_manager, open_scanned_resource)
      is_expected.to be_able_to(:update, open_scanned_resource)
      is_expected.to be_able_to(:update, private_scanned_resource)
      is_expected.to be_able_to(:update, takedown_scanned_resource)
      is_expected.to be_able_to(:update, flagged_scanned_resource)
      is_expected.to be_able_to(:update, ocr_request)
      is_expected.to be_able_to(:destroy, staff_scanned_resource)
      is_expected.to be_able_to(:destroy, staff_file)
      is_expected.to be_able_to(:destroy, ocr_request)
      is_expected.to be_able_to(:download, staff_file)
      is_expected.not_to be_able_to(:destroy, open_scanned_resource)
      is_expected.not_to be_able_to(:destroy, private_scanned_resource)
      is_expected.not_to be_able_to(:destroy, takedown_scanned_resource)
      is_expected.not_to be_able_to(:destroy, flagged_scanned_resource)
      is_expected.not_to be_able_to(:destroy, admin_file)
      is_expected.not_to be_able_to(:destroy, other_staff_file)
      is_expected.to be_able_to(:manifest, open_scanned_resource)
      is_expected.to be_able_to(:read, pending_scanned_resource)
      is_expected.to be_able_to(:manifest, pending_scanned_resource)
      is_expected.to be_able_to(:read, reading_room_scanned_resource)
      is_expected.to be_able_to(:manifest, reading_room_scanned_resource)
      is_expected.to be_able_to(:read, campus_ip_scanned_resource)
      is_expected.to be_able_to(:manifest, campus_ip_scanned_resource)
      is_expected.to be_able_to(:discover, open_scanned_resource)
      is_expected.to be_able_to(:discover, pending_scanned_resource)
      is_expected.to be_able_to(:discover, reading_room_scanned_resource)
      is_expected.to be_able_to(:discover, campus_ip_scanned_resource)
      is_expected.to be_able_to(:read, :graphql)
      is_expected.to be_able_to(:download, no_public_download_open_file)
      is_expected.to be_able_to(:download, token_downloadable_audio_file)
      is_expected.not_to be_able_to(:create, Role.new)
      is_expected.not_to be_able_to(:destroy, role)
    }

    context "when read-only mode is on" do
      before { allow(Figgy).to receive(:read_only_mode).and_return(true) }

      it {
        is_expected.not_to be_able_to(:create, ScannedResource.new)
        is_expected.not_to be_able_to(:create, FileSet.new)
        is_expected.not_to be_able_to(:create, OcrRequest.new)
        is_expected.to be_able_to(:read, open_scanned_resource)
        is_expected.to be_able_to(:read, private_scanned_resource)
        is_expected.to be_able_to(:read, takedown_scanned_resource)
        is_expected.to be_able_to(:read, flagged_scanned_resource)
        is_expected.to be_able_to(:read, ocr_request)
        is_expected.not_to be_able_to(:pdf, open_scanned_resource)
        is_expected.not_to be_able_to(:color_pdf, open_scanned_resource)
        is_expected.not_to be_able_to(:edit, open_scanned_resource)
        is_expected.not_to be_able_to(:edit, private_scanned_resource)
        is_expected.not_to be_able_to(:edit, takedown_scanned_resource)
        is_expected.not_to be_able_to(:edit, flagged_scanned_resource)
        is_expected.not_to be_able_to(:edit, ocr_request)
        is_expected.not_to be_able_to(:file_manager, open_scanned_resource)
        is_expected.not_to be_able_to(:update, open_scanned_resource)
        is_expected.not_to be_able_to(:update, private_scanned_resource)
        is_expected.not_to be_able_to(:update, takedown_scanned_resource)
        is_expected.not_to be_able_to(:update, flagged_scanned_resource)
        is_expected.not_to be_able_to(:update, ocr_request)
        is_expected.not_to be_able_to(:destroy, staff_scanned_resource)
        is_expected.not_to be_able_to(:destroy, staff_file)
        is_expected.to be_able_to(:download, staff_file)
        is_expected.not_to be_able_to(:destroy, open_scanned_resource)
        is_expected.not_to be_able_to(:destroy, private_scanned_resource)
        is_expected.not_to be_able_to(:destroy, takedown_scanned_resource)
        is_expected.not_to be_able_to(:destroy, flagged_scanned_resource)
        is_expected.not_to be_able_to(:destroy, admin_file)
        is_expected.not_to be_able_to(:destroy, other_staff_file)
        is_expected.not_to be_able_to(:destroy, ocr_request)
        is_expected.to be_able_to(:manifest, open_scanned_resource)
        is_expected.to be_able_to(:read, pending_scanned_resource)
        is_expected.to be_able_to(:manifest, pending_scanned_resource)
        is_expected.to be_able_to(:manifest, open_scanned_resource)
        is_expected.to be_able_to(:manifest, pending_scanned_resource)
        is_expected.to be_able_to(:discover, open_scanned_resource)
        is_expected.to be_able_to(:discover, pending_scanned_resource)
        is_expected.to be_able_to(:discover, reading_room_scanned_resource)
        is_expected.to be_able_to(:discover, campus_ip_scanned_resource)
        is_expected.to be_able_to(:read, :graphql)
      }
    end
  end

  describe "as a princeton netid user" do
    let(:creating_user) { staff_user }
    let(:current_user) { netid_user }

    it {
      is_expected.to be_able_to(:read, open_scanned_resource)
      is_expected.to be_able_to(:read, campus_only_scanned_resource)
      is_expected.to be_able_to(:read, complete_scanned_resource)
      is_expected.to be_able_to(:read, flagged_scanned_resource)
      is_expected.to be_able_to(:manifest, open_scanned_resource)
      is_expected.to be_able_to(:manifest, campus_only_scanned_resource)
      is_expected.to be_able_to(:manifest, complete_scanned_resource)
      is_expected.to be_able_to(:manifest, flagged_scanned_resource)
      is_expected.to be_able_to(:pdf, open_scanned_resource)
      is_expected.to be_able_to(:pdf, campus_only_scanned_resource)
      is_expected.to be_able_to(:pdf, complete_scanned_resource)
      is_expected.to be_able_to(:pdf, flagged_scanned_resource)
      is_expected.to be_able_to(:read, :graphql)
      is_expected.to be_able_to(:download, other_staff_file)

      is_expected.not_to be_able_to(:read, private_scanned_resource)
      is_expected.not_to be_able_to(:read, pending_scanned_resource)
      is_expected.not_to be_able_to(:read, metadata_review_scanned_resource)
      is_expected.not_to be_able_to(:read, final_review_scanned_resource)
      is_expected.not_to be_able_to(:read, takedown_scanned_resource)
      is_expected.not_to be_able_to(:read, reading_room_scanned_resource)
      is_expected.not_to be_able_to(:read, ocr_request)
      is_expected.not_to be_able_to(:manifest, reading_room_scanned_resource)
      is_expected.not_to be_able_to(:read, campus_ip_scanned_resource)
      is_expected.not_to be_able_to(:manifest, campus_ip_scanned_resource)
      is_expected.not_to be_able_to(:file_manager, open_scanned_resource)
      is_expected.not_to be_able_to(:update, open_scanned_resource)
      is_expected.not_to be_able_to(:create, ScannedResource.new)
      is_expected.not_to be_able_to(:create, FileSet.new)
      is_expected.not_to be_able_to(:create, OcrRequest.new)
      is_expected.not_to be_able_to(:destroy, other_staff_file)
      is_expected.not_to be_able_to(:destroy, pending_scanned_resource)
      is_expected.not_to be_able_to(:destroy, complete_scanned_resource)
      is_expected.not_to be_able_to(:destroy, ocr_request)
      is_expected.not_to be_able_to(:create, Role.new)
      is_expected.not_to be_able_to(:destroy, role)
      is_expected.not_to be_able_to(:complete, pending_scanned_resource)
      is_expected.not_to be_able_to(:destroy, admin_file)
      is_expected.not_to be_able_to(:download, no_public_download_open_file)
      is_expected.not_to be_able_to(:download, token_downloadable_audio_file)

      is_expected.to be_able_to(:discover, open_scanned_resource)
      is_expected.not_to be_able_to(:discover, pending_scanned_resource)
      is_expected.not_to be_able_to(:discover, reading_room_scanned_resource)
      is_expected.to be_able_to(:discover, campus_ip_scanned_resource)

      # Ephemera Project Contributors
      is_expected.to be_able_to(:read, contributor_ephemera_project)
      is_expected.to be_able_to(:read, contributor_ephemera_folder)
      is_expected.to be_able_to(:read, contributor_ephemera_box)
      is_expected.to be_able_to(:read, contributor_ephemera_folder_in_box)
      is_expected.to be_able_to(:manifest, contributor_ephemera_project)
      is_expected.to be_able_to(:manifest, contributor_ephemera_folder)
      is_expected.to be_able_to(:manifest, contributor_ephemera_box)
      is_expected.to be_able_to(:manifest, contributor_ephemera_folder_in_box)
      is_expected.to be_able_to(:edit, contributor_ephemera_project)
      is_expected.to be_able_to(:edit, contributor_ephemera_folder)
      is_expected.to be_able_to(:edit, contributor_ephemera_box)
      is_expected.to be_able_to(:edit, contributor_ephemera_folder_in_box)
      is_expected.to be_able_to(:update, contributor_ephemera_project)
      is_expected.to be_able_to(:update, contributor_ephemera_folder)
      is_expected.to be_able_to(:update, contributor_ephemera_box)
      is_expected.to be_able_to(:update, contributor_ephemera_folder_in_box)

      is_expected.not_to be_able_to(:delete, contributor_ephemera_project)
      is_expected.not_to be_able_to(:delete, contributor_ephemera_folder)
      is_expected.not_to be_able_to(:delete, contributor_ephemera_box)
      is_expected.not_to be_able_to(:delete, contributor_ephemera_folder_in_box)

      is_expected.not_to be_able_to(:manifest, non_contributor_ephemera_project)
      is_expected.not_to be_able_to(:manifest, non_contributor_ephemera_folder)
      is_expected.not_to be_able_to(:manifest, non_contributor_ephemera_box)
      is_expected.not_to be_able_to(:manifest, non_contributor_ephemera_folder_in_box)
      is_expected.not_to be_able_to(:edit, non_contributor_ephemera_project)
      is_expected.not_to be_able_to(:edit, non_contributor_ephemera_folder)
      is_expected.not_to be_able_to(:edit, non_contributor_ephemera_box)
      is_expected.not_to be_able_to(:edit, non_contributor_ephemera_folder_in_box)
      is_expected.not_to be_able_to(:update, non_contributor_ephemera_project)
      is_expected.not_to be_able_to(:update, non_contributor_ephemera_folder)
      is_expected.not_to be_able_to(:update, non_contributor_ephemera_box)
      is_expected.not_to be_able_to(:update, non_contributor_ephemera_folder_in_box)

      is_expected.not_to be_able_to(:delete, non_contributor_ephemera_project)
      is_expected.not_to be_able_to(:delete, non_contributor_ephemera_folder)
      is_expected.not_to be_able_to(:delete, non_contributor_ephemera_box)
      is_expected.not_to be_able_to(:delete, non_contributor_ephemera_folder_in_box)

      # Controlled digital lending.
      is_expected.to be_able_to(:manifest, private_cdl_scanned_resource)
      is_expected.to be_able_to(:read, private_cdl_scanned_resource)
      is_expected.to be_able_to(:discover, private_cdl_scanned_resource)
      is_expected.not_to be_able_to(:download, private_cdl_scanned_resource.decorate.members.first)
      is_expected.to be_able_to(:manifest, private_cdl_mvw_scanned_resource)
      is_expected.to be_able_to(:read, private_cdl_mvw_scanned_resource)
      is_expected.to be_able_to(:discover, private_cdl_mvw_scanned_resource)
      is_expected.not_to be_able_to(:download, private_cdl_mvw_scanned_resource.decorate.members.first)
      is_expected.not_to be_able_to(:manifest, expired_private_cdl_scanned_resource)
      is_expected.not_to be_able_to(:read, expired_private_cdl_scanned_resource)
      is_expected.to be_able_to(:discover, expired_private_cdl_scanned_resource)
      is_expected.not_to be_able_to(:download, expired_private_cdl_scanned_resource.decorate.members.first)

      # Restricted Viewers
      is_expected.not_to be_able_to(:read, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:manifest, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:discover, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, private_collection_restricted_viewer_scanned_resource.decorate.members.first)

      is_expected.not_to be_able_to(:read, ineligible_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:manifest, ineligible_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, ineligible_restricted_viewer_scanned_resource)
      is_expected.to be_able_to(:discover, ineligible_restricted_viewer_scanned_resource)

      is_expected.to be_able_to(:read, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.to be_able_to(:manifest, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.to be_able_to(:discover, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, reading_room_collection_restricted_viewer_scanned_resource.decorate.members.first)
    }

    context "when accessing figgy via a campus IP" do
      subject { described_class.new(current_user, ip_address: "128.112.0.0") }

      it {
        is_expected.to be_able_to(:read, campus_ip_scanned_resource)
        is_expected.to be_able_to(:manifest, campus_ip_scanned_resource)
      }
    end

    context "with an allowed reading room IP" do
      subject { described_class.new(current_user, ip_address: "1.2.3") }
      let(:config_hash) { { "access_control" => { "reading_room_ips" => ["1.2.3"] } } }
      before do
        allow(Figgy).to receive(:config).and_return(config_hash)
      end
      it {
        is_expected.not_to be_able_to(:read, reading_room_scanned_resource)
        is_expected.not_to be_able_to(:manifest, reading_room_scanned_resource)
        is_expected.to be_able_to(:discover, reading_room_scanned_resource)
      }
    end

    context "when read-only mode is on" do
      before { allow(Figgy).to receive(:read_only_mode).and_return(true) }

      it {
        is_expected.to be_able_to(:read, open_scanned_resource)
        is_expected.to be_able_to(:read, campus_only_scanned_resource)
        is_expected.to be_able_to(:read, complete_scanned_resource)
        is_expected.to be_able_to(:read, flagged_scanned_resource)
        is_expected.to be_able_to(:manifest, open_scanned_resource)
        is_expected.to be_able_to(:manifest, campus_only_scanned_resource)
        is_expected.to be_able_to(:manifest, complete_scanned_resource)
        is_expected.to be_able_to(:manifest, flagged_scanned_resource)
        is_expected.not_to be_able_to(:pdf, open_scanned_resource)
        is_expected.not_to be_able_to(:pdf, campus_only_scanned_resource)
        is_expected.not_to be_able_to(:pdf, complete_scanned_resource)
        is_expected.not_to be_able_to(:pdf, flagged_scanned_resource)
        is_expected.to be_able_to(:read, :graphql)
        is_expected.to be_able_to(:download, other_staff_file)

        is_expected.not_to be_able_to(:read, private_scanned_resource)
        is_expected.not_to be_able_to(:read, pending_scanned_resource)
        is_expected.not_to be_able_to(:read, metadata_review_scanned_resource)
        is_expected.not_to be_able_to(:read, final_review_scanned_resource)
        is_expected.not_to be_able_to(:read, takedown_scanned_resource)
        is_expected.not_to be_able_to(:read, ocr_request)
        is_expected.not_to be_able_to(:file_manager, open_scanned_resource)
        is_expected.not_to be_able_to(:update, open_scanned_resource)
        is_expected.not_to be_able_to(:create, ScannedResource.new)
        is_expected.not_to be_able_to(:create, FileSet.new)
        is_expected.not_to be_able_to(:create, OcrRequest.new)
        is_expected.not_to be_able_to(:destroy, other_staff_file)
        is_expected.not_to be_able_to(:destroy, pending_scanned_resource)
        is_expected.not_to be_able_to(:destroy, complete_scanned_resource)
        is_expected.not_to be_able_to(:destroy, ocr_request)
        is_expected.not_to be_able_to(:create, Role.new)
        is_expected.not_to be_able_to(:destroy, role)
        is_expected.not_to be_able_to(:complete, pending_scanned_resource)
        is_expected.not_to be_able_to(:destroy, admin_file)
      }
    end

    context "with a campus only vector resource" do
      let(:campus_only_vector_resource) { FactoryBot.create_for_repository(:complete_campus_only_vector_resource, user: creating_user) }
      let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:persister) { adapter.persister }
      let(:query_service) { adapter.query_service }
      let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
      let(:vector_resource_members) { query_service.find_members(resource: vector_resource) }
      let(:file_set) { vector_resource_members.first }
      let(:vector_file) do
        DownloadsController::FileWithMetadata.new(
          id: "1234",
          file: "",
          mime_type: "application/vnd.geo+json",
          original_name: "file.geosjon",
          file_set_id: file_set.id,
          file_metadata: file_set.file_metadata.first
        )
      end
      let(:vector_resource) do
        change_set_persister.save(change_set: VectorResourceChangeSet.new(campus_only_vector_resource, files: [file]))
      end
      let(:shoulder) { "99999/fk4" }
      let(:blade) { "123456" }
      before do
        stub_ezid(shoulder: shoulder, blade: blade)
      end

      it {
        is_expected.to be_able_to(:download, vector_file)
      }
    end
  end

  describe "as a reading room user" do
    subject { described_class.new(current_user, ip_address: "1.2.3") }
    let(:creating_user) { staff_user }
    let(:current_user) { reading_room_user }

    context "without an allowed IP" do
      it {
        is_expected.not_to be_able_to(:read, reading_room_scanned_resource)
        is_expected.not_to be_able_to(:manifest, reading_room_scanned_resource)
        is_expected.not_to be_able_to(:discover, reading_room_scanned_resource)
      }
    end

    context "with an allowed IP" do
      let(:config_hash) { { "access_control" => { "reading_room_ips" => ["1.2.3"] } } }
      before do
        allow(Figgy).to receive(:config).and_return(config_hash)
      end
      it {
        is_expected.to be_able_to(:read, reading_room_scanned_resource)
        is_expected.to be_able_to(:manifest, reading_room_scanned_resource)
        is_expected.to be_able_to(:discover, reading_room_scanned_resource)
      }
    end
  end

  describe "as an anonymous user" do
    let(:creating_user) { staff_user }
    let(:current_user) { nil }
    let(:color_enabled_resource) do
      FactoryBot.build(:open_scanned_resource, user: creating_user, state: "complete", pdf_type: ["color"])
    end
    let(:no_pdf_scanned_resource) do
      FactoryBot.build(:open_scanned_resource, user: creating_user, state: "complete", pdf_type: [])
    end
    let(:ephemera_folder) { FactoryBot.create_for_repository(:ephemera_folder, user: current_user) }
    let(:open_vector_resource) { FactoryBot.create_for_repository(:complete_open_vector_resource, user: creating_user) }
    let(:private_vector_resource) { FactoryBot.create_for_repository(:complete_private_vector_resource, user: creating_user) }
    let(:monogram) { FactoryBot.create_for_repository(:numismatic_monogram) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:persister) { adapter.persister }
    let(:query_service) { adapter.query_service }
    let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
    let(:vector_resource_members) { query_service.find_members(resource: vector_resource) }
    let(:file_set) { vector_resource_members.first }
    let(:vector_file) do
      DownloadsController::FileWithMetadata.new(
        id: "1234",
        file: "",
        mime_type: "application/vnd.geo+json",
        original_name: "file.geosjon",
        file_set_id: file_set.id,
        file_metadata: instance_double(FileMetadata, derivative?: false, derivative_partial?: false)
      )
    end
    let(:metadata_file) do
      DownloadsController::FileWithMetadata.new(
        id: "5768",
        file: "",
        mime_type: "application/xml; schema=fgdc",
        original_name: "fgdc.xml",
        file_set_id: file_set.id,
        file_metadata: instance_double(FileMetadata, derivative?: false, derivative_partial?: false)
      )
    end
    let(:thumbnail_file) do
      DownloadsController::FileWithMetadata.new(
        id: "9abc",
        file: "",
        mime_type: "image/png",
        original_name: "thumbnail.png",
        file_set_id: file_set.id,
        file_metadata: instance_double(FileMetadata, derivative?: true)
      )
    end

    it {
      is_expected.to be_able_to(:read, open_scanned_resource)
      is_expected.to be_able_to(:read, open_file_set)
      is_expected.to be_able_to(:manifest, open_scanned_resource)
      is_expected.to be_able_to(:pdf, open_scanned_resource)
      is_expected.to be_able_to(:read, complete_scanned_resource)
      is_expected.to be_able_to(:manifest, complete_scanned_resource)
      is_expected.to be_able_to(:read, flagged_scanned_resource)
      is_expected.to be_able_to(:manifest, flagged_scanned_resource)
      is_expected.to be_able_to(:color_pdf, color_enabled_resource)
      is_expected.to be_able_to(:read, :graphql)
      is_expected.to be_able_to(:download, open_file)
      is_expected.to be_able_to(:read, monogram)
      is_expected.not_to be_able_to(:pdf, no_pdf_scanned_resource)
      is_expected.not_to be_able_to(:flag, open_scanned_resource)
      is_expected.not_to be_able_to(:read, campus_only_scanned_resource)
      is_expected.not_to be_able_to(:read, private_scanned_resource)
      is_expected.not_to be_able_to(:read, pending_scanned_resource)
      is_expected.not_to be_able_to(:read, metadata_review_scanned_resource)
      is_expected.not_to be_able_to(:read, final_review_scanned_resource)
      is_expected.not_to be_able_to(:read, takedown_scanned_resource)
      is_expected.not_to be_able_to(:read, reading_room_scanned_resource)
      is_expected.not_to be_able_to(:read, ocr_request)
      is_expected.not_to be_able_to(:manifest, reading_room_scanned_resource)
      is_expected.not_to be_able_to(:manifest, ephemera_folder)
      is_expected.not_to be_able_to(:file_manager, open_scanned_resource)
      is_expected.not_to be_able_to(:update, open_scanned_resource)
      is_expected.not_to be_able_to(:update, ocr_request)
      is_expected.not_to be_able_to(:create, ScannedResource.new)
      is_expected.not_to be_able_to(:create, FileSet.new)
      is_expected.not_to be_able_to(:create, OcrRequest.new)
      is_expected.not_to be_able_to(:destroy, other_staff_file)
      is_expected.not_to be_able_to(:destroy, pending_scanned_resource)
      is_expected.not_to be_able_to(:destroy, complete_scanned_resource)
      is_expected.not_to be_able_to(:create, Role.new)
      is_expected.not_to be_able_to(:destroy, role)
      is_expected.not_to be_able_to(:complete, pending_scanned_resource)
      is_expected.not_to be_able_to(:destroy, admin_file)
      is_expected.not_to be_able_to(:destroy, ocr_request)
      is_expected.not_to be_able_to(:download, no_public_download_open_file)
      is_expected.not_to be_able_to(:download, token_downloadable_audio_file)

      is_expected.to be_able_to(:discover, open_scanned_resource)
      is_expected.not_to be_able_to(:discover, private_scanned_resource)
      is_expected.not_to be_able_to(:discover, pending_scanned_resource)
      is_expected.not_to be_able_to(:discover, reading_room_scanned_resource)
      is_expected.to be_able_to(:discover, campus_ip_scanned_resource)

      # Ephemera Project Contributors
      is_expected.not_to be_able_to(:edit, contributor_ephemera_project)
      is_expected.not_to be_able_to(:edit, contributor_ephemera_folder)
      is_expected.not_to be_able_to(:update, contributor_ephemera_project)
      is_expected.not_to be_able_to(:update, contributor_ephemera_folder)

      # Controlled Digital Lending
      is_expected.to be_able_to(:discover, private_cdl_scanned_resource)
      is_expected.not_to be_able_to(:read, private_cdl_scanned_resource)

      # Restricted Viewers
      is_expected.not_to be_able_to(:read, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:manifest, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:discover, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, private_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, private_collection_restricted_viewer_scanned_resource.decorate.members.first)

      is_expected.not_to be_able_to(:read, ineligible_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:manifest, ineligible_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, ineligible_restricted_viewer_scanned_resource)
      is_expected.to be_able_to(:discover, ineligible_restricted_viewer_scanned_resource)

      is_expected.not_to be_able_to(:read, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:manifest, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.to be_able_to(:discover, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, reading_room_collection_restricted_viewer_scanned_resource)
      is_expected.not_to be_able_to(:download, reading_room_collection_restricted_viewer_scanned_resource.decorate.members.first)
    }

    context "when accessing figgy via a campus IP" do
      subject { described_class.new(current_user, ip_address: "128.112.0.0") }

      it {
        is_expected.to be_able_to(:read, campus_ip_scanned_resource)
        is_expected.to be_able_to(:manifest, campus_ip_scanned_resource)
      }
    end

    context "when read-only mode is on" do
      before { allow(Figgy).to receive(:read_only_mode).and_return(true) }

      it {
        is_expected.to be_able_to(:read, open_scanned_resource)
        is_expected.to be_able_to(:read, open_file_set)
        is_expected.to be_able_to(:manifest, open_scanned_resource)
        is_expected.not_to be_able_to(:pdf, open_scanned_resource)
        is_expected.to be_able_to(:read, complete_scanned_resource)
        is_expected.to be_able_to(:manifest, complete_scanned_resource)
        is_expected.to be_able_to(:read, flagged_scanned_resource)
        is_expected.to be_able_to(:manifest, flagged_scanned_resource)
        is_expected.not_to be_able_to(:color_pdf, color_enabled_resource)
        is_expected.to be_able_to(:read, :graphql)
        is_expected.to be_able_to(:download, open_file)
        is_expected.not_to be_able_to(:pdf, no_pdf_scanned_resource)
        is_expected.not_to be_able_to(:flag, open_scanned_resource)
        is_expected.not_to be_able_to(:read, campus_only_scanned_resource)
        is_expected.not_to be_able_to(:read, private_scanned_resource)
        is_expected.not_to be_able_to(:read, pending_scanned_resource)
        is_expected.not_to be_able_to(:read, metadata_review_scanned_resource)
        is_expected.not_to be_able_to(:read, final_review_scanned_resource)
        is_expected.not_to be_able_to(:read, takedown_scanned_resource)
        is_expected.not_to be_able_to(:manifest, ephemera_folder)
        is_expected.not_to be_able_to(:file_manager, open_scanned_resource)
        is_expected.not_to be_able_to(:update, open_scanned_resource)
        is_expected.not_to be_able_to(:create, ScannedResource.new)
        is_expected.not_to be_able_to(:create, FileSet.new)
        is_expected.not_to be_able_to(:destroy, other_staff_file)
        is_expected.not_to be_able_to(:destroy, pending_scanned_resource)
        is_expected.not_to be_able_to(:destroy, complete_scanned_resource)
        is_expected.not_to be_able_to(:create, Role.new)
        is_expected.not_to be_able_to(:destroy, role)
        is_expected.not_to be_able_to(:complete, pending_scanned_resource)
        is_expected.not_to be_able_to(:destroy, admin_file)
      }
    end

    context "with an open vector resource" do
      let(:vector_resource) do
        change_set_persister.save(change_set: VectorResourceChangeSet.new(open_vector_resource, files: [file]))
      end
      let(:shoulder) { "99999/fk4" }
      let(:blade) { "123456" }
      before do
        stub_ezid(shoulder: shoulder, blade: blade)
      end

      it {
        is_expected.to be_able_to(:download, thumbnail_file)
        is_expected.to be_able_to(:download, metadata_file)
        is_expected.to be_able_to(:download, vector_file)
      }
    end

    context "with a private vector resource" do
      let(:vector_resource) do
        change_set_persister.save(change_set: VectorResourceChangeSet.new(private_vector_resource, files: [file]))
      end
      let(:shoulder) { "99999/fk4" }
      let(:blade) { "123456" }
      before do
        stub_ezid(shoulder: shoulder, blade: blade)
      end

      it {
        is_expected.to be_able_to(:download, thumbnail_file)
        is_expected.to be_able_to(:download, metadata_file)
        is_expected.not_to be_able_to(:download, vector_file)
      }
    end
  end

  describe "token auth" do
    subject(:ability) { described_class.new(nil, auth_token: token) }

    let(:creating_user) { admin_user }
    let(:private_vector_resource) { FactoryBot.create_for_repository(:complete_private_vector_resource, user: creating_user) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:file) { fixture_file_upload("files/vector/geo.json", "application/vnd.geo+json") }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
    let(:vector_resource) do
      change_set_persister.save(change_set: VectorResourceChangeSet.new(private_vector_resource, files: [file]))
    end

    context "with an admin auth token" do
      let(:token) { AuthToken.create(label: "Test", group: ["admin"]).token }

      it "uses the auth token" do
        expect(ability.current_user.admin?).to be true
      end

      it "provides access to a resource" do
        is_expected.to be_able_to(:read, vector_resource)
        is_expected.to be_able_to(:download, no_public_download_open_file)
        is_expected.to be_able_to(:download, token_downloadable_audio_file)
      end
    end

    context "with an anonymous token" do
      let(:token) { complete_playlist.auth_token }

      it "allows downloading the token's corresponding item" do
        is_expected.to be_able_to(:download, token_downloadable_audio_file)
        is_expected.not_to be_able_to(:download, no_public_download_open_file)
      end
    end

    context "without an auth token" do
      let(:token) { nil }

      before do
        allow(AuthToken).to receive(:find_by).and_call_original
      end

      it "is anonymous" do
        expect(ability.current_user.admin?).to be false
        expect(ability.current_user.anonymous?).to be true
        expect(AuthToken).not_to have_received(:find_by)
      end

      it "preserves the access controls to a resource" do
        is_expected.not_to be_able_to(:read, vector_resource)
      end
    end

    context "when read-only mode is on" do
      before { allow(Figgy).to receive(:read_only_mode).and_return(true) }
      let(:token) { AuthToken.create(label: "Test", group: ["admin"]).token }

      it "provides access to a resource" do
        is_expected.to be_able_to(:read, vector_resource)
      end

      it "prohibits write access to a resource" do
        is_expected.not_to be_able_to(:update, vector_resource)
        is_expected.not_to be_able_to(:create, vector_resource)
        is_expected.not_to be_able_to(:destroy, vector_resource)
      end
    end
  end
end
