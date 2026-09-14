require "rails_helper"

RSpec.describe EventGenerator::GeoblacklightEventGenerator do
  subject(:event_generator) { described_class.new }
  let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032).to_s }
  let(:record) { FactoryBot.create_for_repository(:complete_scanned_map, coverage: coverage) }

  it_behaves_like "an EventGenerator"

  describe "#record_deleted" do
    it "enqueues a delete job" do
      slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug

      expect { event_generator.record_deleted(record) }
        .to have_enqueued_job(PulmapDeleteJob).with(slug: slug, commit: true)
    end
  end

  describe "#record_updated" do
    context "with a record in a completed state" do
      it "enqueues an index job with the geoblacklight document" do
        gbl_doc = GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new).to_json

        expect { event_generator.record_updated(record) }
          .to have_enqueued_job(PulmapIndexJob).with(document: gbl_doc, commit: true)
      end
    end

    context "with a record updated as part of a bulk operation" do
      subject(:event_generator) { described_class.new(bulk: true) }

      it "enqueues an index job that does not commit" do
        gbl_doc = GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new).to_json

        expect { event_generator.record_updated(record) }
          .to have_enqueued_job(PulmapIndexJob).with(document: gbl_doc, commit: false)
      end
    end

    context "with a record in a takedown state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "takedown") }

      it "enqueues a delete job" do
        slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug

        expect { event_generator.record_updated(record) }
          .to have_enqueued_job(PulmapDeleteJob).with(slug: slug, commit: true)
      end
    end

    context "with a record in a pending state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "pending") }

      it "does not enqueue a job" do
        expect { event_generator.record_updated(record) }.not_to have_enqueued_job
      end
    end
  end

  describe "#record_member_updated" do
    context "with a record in a completed state" do
      it "enqueues an index job with the geoblacklight document" do
        gbl_doc = GeoDiscovery::DocumentBuilder.new(record, GeoDiscovery::GeoblacklightDocument.new).to_json

        expect { event_generator.record_member_updated(record) }
          .to have_enqueued_job(PulmapIndexJob).with(document: gbl_doc, commit: true)
      end
    end

    context "with a record in a takedown state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "takedown") }

      it "enqueues a delete job" do
        slug = GeoDiscovery::DocumentBuilder::SlugBuilder.new(record).slug

        expect { event_generator.record_member_updated(record) }
          .to have_enqueued_job(PulmapDeleteJob).with(slug: slug, commit: true)
      end
    end

    context "with a record in a pending state" do
      let(:record) { FactoryBot.create_for_repository(:scanned_map, state: "pending") }

      it "does not enqueue a job" do
        expect { event_generator.record_member_updated(record) }.not_to have_enqueued_job
      end
    end
  end

  describe "#valid?" do
    context "with a fileset" do
      let(:record) { FactoryBot.create_for_repository(:file_set) }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "with a scanned resource" do
      let(:record) { FactoryBot.create_for_repository(:scanned_resource) }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "when a record generates an invalid geoblacklight document" do
      let(:coverage) { nil }

      it "is not valid" do
        expect(event_generator.valid?(record)).to be false
      end
    end

    context "when a record generates an invalid geoblacklight document" do
      let(:document_builder) { instance_double(GeoDiscovery::DocumentBuilder) }
      before do
        allow(GeoDiscovery::DocumentBuilder).to receive(:new).and_return(document_builder)
        allow(document_builder).to receive(:to_hash).and_raise(StandardError)
      end

      it "still emits a valid event" do
        expect(event_generator.valid?(record)).to be true
      end
    end
  end
end
