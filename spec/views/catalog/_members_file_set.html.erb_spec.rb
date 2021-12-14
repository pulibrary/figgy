# frozen_string_literal: true
require "rails_helper"

RSpec.describe "catalog/_members_file_set" do
  let(:original_file) { FileMetadata.new(id: "test-original-file", use: [Valkyrie::Vocab::PCDMUse.OriginalFile]) }
  let(:derivative_file) { FileMetadata.new(id: "test-derivative-file", use: [Valkyrie::Vocab::PCDMUse.ServiceFile], mime_type: "application/x-mpegURL") }
  let(:derivative_file_partial) { FileMetadata.new(id: "test-derivative-file-partial", use: [Valkyrie::Vocab::PCDMUse.ServiceFilePartial]) }
  let(:cloud_derivative_file) { FileMetadata.new(id: "test-cloud-derivative-file", label: "display_raster.tiff", use: [Valkyrie::Vocab::PCDMUse.CloudDerivative], mime_type: "application/x-mpegURL") }
  let(:thumbnail_file) { FileMetadata.new(id: "test-thumbnail-file", use: [Valkyrie::Vocab::PCDMUse.ThumbnailImage]) }
  let(:file_set) do
    FactoryBot.create_for_repository(:file_set, file_metadata: [original_file, derivative_file, thumbnail_file, derivative_file_partial, cloud_derivative_file])
  end
  let(:parent) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [file_set.id]) }
  let(:solr) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:document) { solr.resource_factory.from_resource(resource: file_set) }
  let(:solr_document) { SolrDocument.new(document) }
  let(:user) { FactoryBot.create(:user) }

  before do
    parent
    assign :resource, file_set
    assign :document, solr_document
    sign_in user
    render
  end

  it "hides the upload form field for original files" do
    expect(rendered).not_to have_css "input.file[name='file_set[files[][#{original_file.id}]]']"
  end
  it "hides the upload form field for derivative files" do
    expect(rendered).not_to have_css "input.file[name='file_set[derivative_files[][#{derivative_file.id}]]']"
  end
  it "hides the upload form field for thumbnail files" do
    expect(rendered).not_to have_css "input.file[name='file_set[thumbnail_files[][#{thumbnail_file.id}]]']"
  end
  it "hides the submit button for updating files" do
    expect(rendered).not_to have_css "input[type='submit'][value='Update Files']"
  end

  it "hides the download link for original files" do
    expect(rendered).not_to have_link "Download", href: download_path(resource_id: file_set.id, id: original_file.id)
  end
  it "hides the download link for derivative files" do
    expect(rendered).not_to have_link "Download", href: download_path(resource_id: file_set.id, id: derivative_file.id)
  end
  it "hides the download link for thumbnail files" do
    expect(rendered).not_to have_link "Download", href: download_path(resource_id: file_set.id, id: thumbnail_file.id)
  end

  context "as an admin. user" do
    let(:user) { FactoryBot.create(:admin) }
    it "does not render an upload form field for original files" do
      expect(rendered).not_to have_css "input.file[name='file_set[files[][#{original_file.id}]]']"
    end

    it "does not render an upload form field for derivative files" do
      expect(rendered).not_to have_css "input.file[name='file_set[derivative_files[][#{derivative_file.id}]]']"
    end

    it "does not render an upload form field for thumbnail files" do
      expect(rendered).not_to have_css "input.file[name='file_set[thumbnail_files[][#{thumbnail_file.id}]]']"
    end

    it "does not render the submit button for updating files" do
      expect(rendered).not_to have_css "input[type='submit'][value='Update Files']"
    end

    it "renders the download link for original files" do
      expect(rendered).to have_link "Download", href: download_path(resource_id: file_set.id, id: original_file.id)
    end

    it "renders the download link for derivative files" do
      expect(rendered).to have_link "Download", href: download_path(resource_id: file_set.id, id: derivative_file.id)
      expect(rendered).to have_text "(1 Partials)"
    end

    it "renders the title of the cloud derivative files" do
      expect(rendered).to have_text "Cloud Derivative File"
      expect(rendered).to have_text "display_raster.tiff"
    end

    it "renders the download link for thumbnail files" do
      expect(rendered).to have_link "Download", href: download_path(resource_id: file_set.id, id: thumbnail_file.id)
    end

    it "renders a summary for derivative partials" do
      expect(rendered).not_to have_link "Download", href: download_path(resource_id: file_set.id, id: derivative_file_partial.id)
    end
  end
end
