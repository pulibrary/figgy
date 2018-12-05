# frozen_string_literal: true
require "rails_helper"

RSpec.describe MusicImportService do
  let(:importer) { described_class.new(sql_server_adapter: sql_server_adapter, postgres_adapter: postgres_adapter, logger: logger, cache: false) }
  let(:sql_server_adapter) { instance_double MusicImportService::TinyTdsAdapter }
  let(:postgres_adapter) { instance_double MusicImportService::PgAdapter }
  let(:logger) { instance_double Logger }

  before do
    allow(logger).to receive(:info)
    allow(sql_server_adapter).to receive(:execute).with(query: importer.recordings_collector.recordings_query).and_return music_fixtures
    allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: "CD- 9455")).and_return(
      [{ "title" => "Piano sonatas [sound recording] / Beethoven.", "bibid" => "1791261" }]
    )
    allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: "CD- 431")).and_return(
      [{ "title" => "4 titles with this call number", "bibid" => "?f[call_number_browse_s][]=CD-+9221" }]
    )
    allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: "X-MUS257RAKHA")).and_return []
    allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "sort", call_num: "X-MUS257RAKHA")).and_return []
    stub_request(:get, "https://catalog.princeton.edu/catalog.json?f%5Bcall_number_browse_s%5D%5B0%5D=CD-%20431&search_field=all_fields")
      .to_return(status: 200, body: ol_fixture.to_json, headers: {})
    stub_request(:get, /https:\/\/bibdata.princeton.edu\/bibliographic\/.*/)
      .to_return(status: 404)
  end

  describe "caching" do
    let(:importer) { described_class.new(sql_server_adapter: sql_server_adapter, postgres_adapter: postgres_adapter, logger: logger, cache: true) }
    let(:importer_args) do
      {
        sql_server_adapter: sql_server_adapter, postgres_adapter: postgres_adapter, logger: logger, cache: MusicImportService::RecordingCollector::MarshalCache.new("tmp/test")
      }
    end
    before do
      FileUtils.rm_f("tmp/test/recordings_cache.dump")
      FileUtils.rm_f("tmp/test/cached_bibs.dump")
    end
    it "caches everything to a file" do
      described_class.new(importer_args).recordings
      described_class.new(importer_args).recordings
      described_class.new(importer_args).recordings

      expect(File.exist?("tmp/test/recordings_cache.dump")).to eq true
      expect(File.exist?("tmp/test/cached_bibs.dump")).to eq true
      expect(sql_server_adapter).to have_received(:execute).exactly(1).times
      expect(a_request(:get, /https:\/\/bibdata.princeton.edu\/bibliographic\/.*/)).to have_been_made.times(2)
    end
  end

  describe "#process_recordings" do
    it "returns recordings with course numbers and bib ids" do
      recordings = importer.recordings
      expect(recordings.map(&:id)).to include(14, 15)
      expect(recordings.map(&:call)).to include("cd-9455", "cd-431v1")
      expect(recordings.map(&:courses)).to include(["mus204", "mus549sb"], [], ["borris"])
      expect(recordings.map(&:bibs)).to include(["1791261"], ["2547641", "2686069"])
    end
  end

  describe "#call_number_report" do
    it "reports total bibs and breakdown by course type" do
      importer.bibid_report
      expect(logger).to have_received(:info).with("Bib ids found in 0 of 1 recordings (suspected playlists) where call number starts with 'x-' (0%)")
      expect(logger).to have_received(:info).with("Bib ids found in 2 of 3 recordings (66%)")
      expect(logger).to have_received(:info).with("Bib ids found in 1 of 1 recordings with numbered course names (100%)")
      expect(logger).to have_received(:info).with("Bib ids found in 1 of 1 recordings with other course names (100%)")
      expect(logger).to have_received(:info).with("1 recordings not in any course")
    end
  end

  describe "#extra_bibs_csv" do
    it "populates the fields of the csv, one row per recording" do
      csv = importer.extra_bibs_csv
      expect(csv).to eq "id,call,courses,titles,bibs,recommended_bib,final_bib\n" + "15,cd-431v1,\"[\"\"mus204\"\", \"\"mus549sb\"\"]\",[],\"[\"\"2547641\"\", \"\"2686069\"\"]\",\n"
    end
  end

  context "a recording with no call number or bib number" do
    describe "#process_recordings" do
      before do
        allow(sql_server_adapter).to receive(:execute).with(query: importer.recordings_collector.recordings_query).and_return [{ "idRecording" => 15, "CallNo" => nil, "CourseNo" => "mus204" }]
      end
      it "returns a recording with no call number" do
        recording = importer.recordings.first
        expect(recording.call).to be_nil
        expect(recording.courses).to include("mus204")
        expect(recording.bibs).to eq []
      end
    end
  end

  context "call number containing single quote" do
    describe "#process_recordings" do
      let(:bad_call) { "'T LIKE -CRANE.MP3" }
      let(:escaped_call) { "''T LIKE -CRANE.MP3" }
      let(:escaped_call2) { "''T LIKE -CRANE.MP0000003" }
      before do
        allow(sql_server_adapter).to receive(:execute).with(query: importer.recordings_collector.recordings_query).and_return [{ "idRecording" => 15, "CallNo" => "'t Like -Crane.mp3" }]
        allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: escaped_call)).and_return []
        allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "sort", call_num: escaped_call2)).and_return []
      end
      it "escapes the quote for the query" do
        importer.recordings
        expect(postgres_adapter).to have_received(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: escaped_call)).exactly(4).times
        expect(postgres_adapter).not_to have_received(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: bad_call))
      end
    end
  end

  context "a call number that never hits a bib" do
    describe "#process_recordings" do
      before do
        allow(sql_server_adapter).to receive(:execute).with(query: importer.recordings_collector.recordings_query).and_return [{ "idRecording" => 3014, "CallNo" => "cd-123", "CourseNo" => nil }]
        allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: "CD- 123")).and_return []
        allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "label", call_num: "CD 123")).and_return []
        allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "sort", call_num: "CD 0000123")).and_return []
        allow(postgres_adapter).to receive(:execute).with(query: importer.recordings_collector.bib_query(column: "sort", call_num: "CD0000123")).and_return []
      end
      it "checks every kind of normalization and gets []" do
        recordings = importer.recordings
        expect(recordings.first.bibs).to eq []
      end
    end
  end

  def music_fixtures
    [{ "idRecording" => 14, "CallNo" => "cd-9455", "CourseNo" => "borris" },
     { "idRecording" => 15, "CallNo" => "cd-431v1", "CourseNo" => "mus204" },
     { "idRecording" => 15, "CallNo" => "cd-431v1", "CourseNo" => "mus549sb" },
     { "idRecording" => 3223, "CallNo" => "x-mus257rakha", "CourseNo" => nil },
     { "idRecording" => 3014, "CallNo" => nil, "CourseNo" => nil }]
  end

  def ol_fixture
    { response: {
      docs: [
        { id: "2547641",
          title_display: "Symphonies nos. 55-69 [sound recording] / Haydn." },
        { id: "2686069",
          title_display: "Symphonies nos. 1-20 [sound recording] / Haydn." }
      ]
    } }
  end
end
