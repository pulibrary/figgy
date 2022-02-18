# frozen_string_literal: true

require "rails_helper"

describe FindingAidsUpdater do
  with_queue_adapter :inline

  let(:updater) { described_class.new(logger: Logger.new(nil)) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:success) { instance_double Process::Status }
  let(:logger) { instance_double Logger }

  let(:r1) do
    Timecop.freeze(Time.now.utc - 1.week) do
      resource = FactoryBot.build(:scanned_resource, title: [])
      cs1 = ChangeSet.for(resource)
      cs1.validate(source_metadata_identifier: "C0652_c0389")
      persister.save(change_set: cs1)
    end
  end

  let(:r2) do
    Timecop.freeze(Time.now.utc - 1.week) do
      resource = FactoryBot.build(:scanned_resource, title: [])
      cs2 = ChangeSet.for(resource)
      cs2.validate(source_metadata_identifier: "MC016_c9616")
      persister.save(change_set: cs2)
    end
  end

  let(:r3) do
    Timecop.freeze(Time.now.utc - 1.week) do
      resource = FactoryBot.build(:scanned_resource, title: [])
      cs3 = ChangeSet.for(resource)
      cs3.validate(source_metadata_identifier: "AC044_c0003")
      persister.save(change_set: cs3)
    end
  end

  let(:r4) do
    Timecop.freeze(Time.now.utc - 1.week) do
      # A resource with no source metadata id
      FactoryBot.create_for_repository(:scanned_resource)
    end
  end

  let(:r5) do
    Timecop.freeze(Time.now.utc - 1.week) do
      # A bibid resource
      resource = FactoryBot.build(:scanned_resource, title: [])
      cs5 = ChangeSet.for(resource)
      cs5.validate(source_metadata_identifier: "4609321")
      persister.save(change_set: cs5)
    end
  end

  before do
    stub_pulfa(pulfa_id: "C0652_c0389")
    stub_pulfa(pulfa_id: "MC016_c9616")
    stub_pulfa(pulfa_id: "AC044_c0003")
    stub_bibdata(bib_id: "4609321")
    r1
    r2
    r3
    r4
    r5
    allow(logger).to receive(:info)
    allow(Rails).to receive(:logger).and_return(logger)
    allow(success).to receive(:success?).and_return(true)
    allow(Open3).to receive(:capture2)
      .with("svn diff --summarize -r {#{Time.zone.yesterday.to_formatted_s(:iso8601)}}:HEAD --username tester --password testing http://example.com/svn/pulfa/trunk/eads")
      .and_return([svn_fixture, success])
  end

  describe ".yesterday" do
    it "updates only the resources that svn reports as updated" do
      updater.yesterday
      expect(query_service.find_by(id: r1.id).updated_at).to be_today
      expect(query_service.find_by(id: r2.id).updated_at).to be_today
      expect(query_service.find_by(id: r3.id).updated_at).not_to be_today
      expect(query_service.find_by(id: r4.id).updated_at).not_to be_today
      expect(query_service.find_by(id: r5.id).updated_at).not_to be_today
    end
  end

  describe ".all" do
    it "updates all pulfa resources" do
      updater.all
      expect(query_service.find_by(id: r1.id).updated_at).to be_today
      expect(query_service.find_by(id: r2.id).updated_at).to be_today
      expect(query_service.find_by(id: r3.id).updated_at).to be_today
      expect(query_service.find_by(id: r4.id).updated_at).not_to be_today
      expect(query_service.find_by(id: r5.id).updated_at).not_to be_today
    end
  end

  def svn_fixture
    <<~HEREDOC
      M       http://diglibsvn.princeton.edu/svn/pulfa/trunk/eads/mss/C0652.EAD.xml
      M       http://diglibsvn.princeton.edu/svn/pulfa/trunk/eads/mudd/publicpolicy/MC016.EAD.xml
    HEREDOC
  end

  def persister
    @persister ||= ChangeSetPersister.new(metadata_adapter: Valkyrie.config.metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter)
  end
end
