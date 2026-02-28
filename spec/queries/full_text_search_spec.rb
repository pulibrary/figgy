require "rails_helper"

RSpec.describe FullTextSearch do
  let(:persister) { Valkyrie::MetadataAdapter.find(:indexing_persister).persister }
  let(:file) { fixture_file_upload("GNIB/00223/00223.tif", "image/tiff") }
  let(:query_service) { ChangeSetPersister.default.query_service }
  let(:hocr_content) { File.read(Rails.root.join("spec", "fixtures", "hocr.hocr")) }
  let(:ocr_content) { File.read(Rails.root.join("spec", "fixtures", "ocr.txt")) }
  it "returns full text search results" do
      parent = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      file = query_service.find_members(resource: parent).first
      change_set = ChangeSet.for(file)
      change_set.validate(ocr_content: ocr_content, hocr_content: hocr_content)
      ChangeSetPersister.default.save(change_set: change_set)

      files = ChangeSetPersister.default.query_service.custom_queries.full_text_search(id: parent.id, text: "the fixation of belief")
      expect(files.length).to eq 1
      expect(files.first.highlights).to eq ["<em>FIXATION</em> OF <em>BELIEF</em>", "<em>FIXATION</em> OF <em>BELIEF</em>"]

      files = ChangeSetPersister.default.query_service.custom_queries.full_text_search(id: parent.id, text: "No text should match")
      expect(files.length).to eq 0
  end
end
