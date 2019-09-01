# frozen_string_literal: true
require "rails_helper"

RSpec.describe PulfaExporter do
  let(:svn_client) { PulfaExporter::SvnClient.new(dry_run: true, logger: logger) }
  let(:logger) { Logger.new(IO::NULL) }
  let(:svn_dir) { Rails.root.join("tmp", "svn") }
  let(:eads_dir) { Rails.root.join("tmp", "svn", "pulfa", "eads") }
  let(:fixture_ead) { Rails.root.join("spec", "fixtures", "files", "pulfa", "C0652.EAD.xml") }
  let(:temp_ead) { Rails.root.join(eads_dir, "C0652.EAD.xml") }
  let(:collection_code) { "C0652" }
  let(:component_code) { "c0377" }
  let(:component_id) { "#{collection_code}_#{component_code}" }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:collection) { FactoryBot.create_for_repository(:collection, source_metadata_identifier: collection_code) }
  let(:resource) do
    r = FactoryBot.build(:complete_scanned_resource, title: [])
    change_set = ScannedResourceChangeSet.new(r)
    change_set.validate(source_metadata_identifier: component_id, state: ["complete"], member_of_collection_ids: [collection.id])
    change_set_persister.save(change_set: change_set)
  end

  let(:ns) { { xlink: "http://www.w3.org/1999/xlink", ead: "urn:isbn:1-931666-22-9" } }
  let(:xpath) { "//ead:dao[@xlink:role='https://iiif.io/api/presentation/2.1/']/@xlink:href" }

  before do
    FileUtils.mkdir_p(eads_dir) unless File.directory?(eads_dir)
    FileUtils.cp(fixture_ead, eads_dir)
    stub_pulfa(pulfa_id: component_id)
    stub_ezid(shoulder: "99999/fk4", blade: "8675309")
    resource
  end

  after do
    FileUtils.rm_rf(svn_dir)
  end

  describe "#export" do
    let(:exporter) { described_class.new(since_date: since_date, logger: logger, svn_client: svn_client) }
    let(:since_date) { (Time.zone.today - 2).strftime("%Y-%m-%d") }

    it "adds a DAO link to the new resource" do
      before = Nokogiri::XML(File.open(temp_ead))
      expect(before.at_xpath(xpath, ns).to_s).to eq ""

      expect { exporter.export }.not_to raise_error

      after = Nokogiri::XML(File.open(temp_ead))
      expect(after.at_xpath(xpath, ns).to_s).to eq "http://www.example.com/concern/scanned_resources/#{resource.id}/manifest"
    end
  end

  describe "#export_pdf" do
    let(:exporter) { described_class.new(since_date: nil, logger: logger, svn_client: svn_client) }

    it "adds a DAO link to exported PDFs" do
      expect { exporter.export_pdf(collection.id) }.not_to raise_error
      after = Nokogiri::XML(File.open(temp_ead))
      expect(after.at_xpath(xpath, ns).to_s).to eq "pdf/#{component_code}.pdf"
    end
  end
end
