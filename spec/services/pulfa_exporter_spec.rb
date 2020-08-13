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
  let(:component_code2) { "c0383" }
  let(:component_id) { "#{collection_code}_#{component_code}" }
  let(:component_id2) { "#{collection_code}_#{component_code2}" }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:collection) { FactoryBot.create_for_repository(:collection, source_metadata_identifier: collection_code) }
  let(:resource) do
    r = FactoryBot.build(:complete_scanned_resource, title: [])
    change_set = ScannedResourceChangeSet.new(r)
    change_set.validate(source_metadata_identifier: component_id, state: ["complete"], member_of_collection_ids: [collection.id])
    change_set_persister.save(change_set: change_set)
  end
  let(:resource2) do
    r = FactoryBot.build(:complete_scanned_resource, title: [])
    change_set = ScannedResourceChangeSet.new(r)
    change_set.validate(source_metadata_identifier: component_id2, state: ["complete"], member_of_collection_ids: [collection.id])
    change_set.validate(member_ids: [vol1.id, vol2.id])
    change_set_persister.save(change_set: change_set)
  end
  let(:vol1) { FactoryBot.create_for_repository(:scanned_resource, title: "Volume 1") }
  let(:vol2) { FactoryBot.create_for_repository(:scanned_resource, title: "Volume 2") }

  let(:ns) { { xlink: "http://www.w3.org/1999/xlink", ead: "urn:isbn:1-931666-22-9" } }
  let(:xpath) { "//ead:dao[@xlink:role='https://iiif.io/api/presentation/2.1/']/@xlink:href" }
  let(:xpath2) { "//ead:dao/@xlink:href" }

  before do
    FileUtils.mkdir_p(eads_dir) unless File.directory?(eads_dir)
    FileUtils.cp(fixture_ead, eads_dir)
    stub_pulfa(pulfa_id: component_id)
    stub_pulfa(pulfa_id: component_id2)
    stub_ezid(shoulder: "99999/fk4", blade: "8675309")
    resource
    resource2
  end

  after do
    FileUtils.rm_rf(svn_dir)
  end

  describe "#export" do
    let(:exporter) { described_class.new(since_date: since_date, logger: logger, svn_client: svn_client) }
    let(:since_date) { (Time.zone.today - 2).strftime("%Y-%m-%d") }

    it "idempotently adds a DAO link to the new resource" do
      before = Nokogiri::XML(File.open(temp_ead))
      expect(before.xpath(xpath, ns).to_a).to eq []

      # run once to test export
      expect { exporter.export }.not_to raise_error
      after = Nokogiri::XML(File.open(temp_ead))
      expect(after.xpath(xpath, ns).map(&:to_s)).to eq [
        "http://www.example.com/concern/scanned_resources/#{resource.id}/manifest",
        "http://www.example.com/concern/scanned_resources/#{resource2.id}/manifest"
      ]

      # run again to test idempotency
      expect { exporter.export }.not_to raise_error
      again = Nokogiri::XML(File.open(temp_ead))
      expect(again.xpath(xpath, ns).map(&:to_s)).to eq [
        "http://www.example.com/concern/scanned_resources/#{resource.id}/manifest",
        "http://www.example.com/concern/scanned_resources/#{resource2.id}/manifest"
      ]
    end

    describe "when there is an error sending email" do
      let(:mailer) { instance_double(PulfaMailer) }

      before do
        allow(Honeybadger).to receive(:notify)
        allow(PulfaMailer).to receive(:with).and_raise(StandardError, "No route to host")
      end

      it "catches and logs the error" do
        expect { exporter.export }.not_to raise_error
        expect(Honeybadger).to have_received(:notify)
      end
    end

    describe "when the finding aid doesn't exist" do
      let(:bogus_objects) { { "XYZ_c123" => [resource2] } }

      before do
        allow(exporter).to receive(:grouped_objects).and_return(bogus_objects)
        allow(Honeybadger).to receive(:notify)
      end

      it "catches and logs the error" do
        expect { exporter.export }.not_to raise_error
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end

  describe "#export_pdf" do
    let(:exporter) { described_class.new(since_date: nil, logger: logger, svn_client: svn_client) }

    it "adds a DAO link to exported PDFs" do
      expect { exporter.export_pdf(collection.id) }.not_to raise_error
      after = Nokogiri::XML(File.open(temp_ead))
      pdf_links = after.xpath(xpath2, ns).map(&:to_s)
      expect(pdf_links).to include("pdf/#{component_code}.pdf")
      expect(pdf_links).to include("pdf/#{component_code2}_0.pdf")
      expect(pdf_links).to include("pdf/#{component_code2}_1.pdf")
    end
  end
end
