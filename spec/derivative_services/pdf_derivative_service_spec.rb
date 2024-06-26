# frozen_string_literal: true
require "rails_helper"
require "valkyrie/derivatives/specs/shared_specs"

RSpec.describe PDFDerivativeService do
  it_behaves_like "a Valkyrie::Derivatives::DerivativeService"

  let(:derivative_service) do
    PDFDerivativeService::Factory.new(change_set_persister: change_set_persister)
  end
  let(:file) { fixture_file_upload("files/sample.pdf", "application/pdf") }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:query_service) { adapter.query_service }
  let(:scanned_resource) do
    change_set_persister.save(change_set: ScannedResourceChangeSet.new(ScannedResource.new, files: [file]))
  end
  let(:book_members) { query_service.find_members(resource: scanned_resource) }
  let(:valid_resource) { book_members.first }
  let(:valid_id) { valid_resource.id }

  describe "#valid?" do
    subject(:valid_file) { derivative_service.new(id: valid_id) }

    context "when given a pdf original_file" do
      it { is_expected.to be_valid }
    end

    context "when given a tiff mime_type" do
      it "is not valid" do
        # rubocop:disable RSpec/SubjectStub
        allow(valid_file).to receive(:mime_type).and_return(["image/tiff"])
        # rubocop:enable RSpec/SubjectStub
        is_expected.not_to be_valid
      end
    end

    context "when given a pdf preservation file" do
      it "is valid" do
        pdf_file_metadata = valid_resource.file_metadata.find { |f| f.use == [::PcdmUse::OriginalFile] }
        pdf_file_metadata.use = [::PcdmUse::PreservationFile]
        valid_resource.file_metadata = [pdf_file_metadata]
        adapter.persister.save(resource: valid_resource)

        is_expected.to be_valid
      end
    end
  end

  describe "#create_derivatives" do
    context "when there are no errors", run_real_derivatives: true, run_real_characterization: true do
      with_queue_adapter :inline
      it "creates an intermediate tiff for each page and marks the pdf as preservation file" do
        valid_resource

        reloaded_members = query_service.find_members(resource: scanned_resource)

        expect(reloaded_members.reject { |fs| fs.preservation_file.nil? }.map(&:id).first).to eq valid_resource.id
        intermediate_files = reloaded_members.reject { |fs| fs.intermediate_file.nil? }
        expect(intermediate_files.count).to eq 2
        expect(intermediate_files.first.title).to eq ["00000001"]
        expect(intermediate_files.last.title).to eq ["00000002"]
        expect(intermediate_files.first.intermediate_file.checksum.first).not_to eq intermediate_files.last.intermediate_file.checksum.first
        # Ensure the derivative is created with a decent size for better
        # quality.
        intermediate_file = intermediate_files.first.intermediate_file
        intermediate_disk_file = Valkyrie::StorageAdapter.find_by(id: intermediate_file.file_identifiers.first)
        vips_image = Vips::Image.new_from_file(intermediate_disk_file.disk_path.to_s)
        # Don't upscale.
        expect(vips_image.width).to eq 612

        # Ensure the thumbnail is set to the first derivative.
        reloaded_resource = query_service.find_by(id: scanned_resource.id)
        expect(reloaded_resource.thumbnail_id).to eq [intermediate_files.first.id]
      end
    end

    context "when there is a vips error" do
      before { valid_resource }
      it "updates the error message and raises" do
        allow(Vips::Image).to receive(:pdfload).and_raise(Vips::Error, "not the pagerange error")
        expect { derivative_service.new(id: valid_resource.id).create_derivatives }.to raise_error(Vips::Error)
        reloaded_members = query_service.find_members(resource: scanned_resource)
        expect(reloaded_members.count).to eq 1
        file_set = reloaded_members.first
        expect(file_set.id).to eq valid_resource.id
        expect(file_set.primary_file.error_message).to include(/not the pagerange error/)
      end

      it "rolls back all changes on failure" do
        service = derivative_service.new(id: valid_resource.id)
        # Fail on second page generation.
        allow(service).to receive(:convert_pdf_page).and_call_original
        allow(service).to receive(:convert_pdf_page).with(anything, anything, 1).and_raise(Vips::Error)
        expect { service.create_derivatives }.to raise_error(Vips::Error)

        reloaded_members = query_service.find_members(resource: scanned_resource)
        expect(reloaded_members.count).to eq 1
        expect(reloaded_members.first.preservation_file).to be_blank
      end

      it "retries generating a page if it creates a zero byte file" do
        service = derivative_service.new(id: valid_resource.id)
        allow(service).to receive(:convert_pdf_page).and_call_original
        call_count = 0
        # Create a zero byte file on the first try of of creating page 1.
        allow(service).to receive(:convert_pdf_page).with(anything, anything, 1) do |arg1, arg2, _page|
          call_count += 1
          raise PDFDerivativeService::ZeroByteError if call_count == 1
          service.convert_pdf_page(arg1, arg2, 0)
        end
        expect { service.create_derivatives }.not_to raise_error

        reloaded_members = query_service.find_members(resource: scanned_resource)
        expect(reloaded_members.count).to eq 3
        file = Valkyrie::StorageAdapter.find_by(id: reloaded_members.last.intermediate_file.file_identifiers.first)
        expect(file.size).not_to eq 0
      end
    end

    context "when there was a previous error", run_real_derivatives: true, run_real_characterization: true do
      it "clears the error on a successful retry" do
        valid_resource

        reloaded_members = query_service.find_members(resource: scanned_resource)

        file_set = reloaded_members.first
        primary_file = file_set.primary_file
        primary_file.error_message = ["some kind of error"]
        file_set.file_metadata = file_set.file_metadata.select { |x| x.id != primary_file.id } + [primary_file]
        adapter.persister.save(resource: file_set)

        derivative_service.new(id: valid_resource.id).create_derivatives

        # ensure the error was cleared
        reloaded_members = query_service.find_members(resource: scanned_resource)
        file_set = reloaded_members.first
        expect(file_set.id).to eq valid_resource.id
        expect(file_set.primary_file.error_message).to be_empty
      end
    end
  end

  describe "#cleanup_derivatives", run_real_derivatives: true, run_real_characterization: true do
    with_queue_adapter :inline
    before { valid_resource }
    it "deletes all intermediate files with original_filename starting 'converted_from_pdf'" do
      derivative_service.new(id: valid_resource.id).cleanup_derivatives

      reloaded_members = query_service.find_members(resource: scanned_resource)
      expect(reloaded_members.count).to eq 1
      expect(reloaded_members.first.id).to eq valid_resource.id

      intermediate_files = reloaded_members.reject { |fs| fs.intermediate_file.nil? }
      expect(intermediate_files).to be_empty
    end
  end
end
