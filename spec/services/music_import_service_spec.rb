# frozen_string_literal: true
require "rails_helper"

RSpec.describe MusicImportService do
  let(:importer) { described_class.new(recording_collector: collector, logger: logger, file_root: Rails.root.join("spec", "fixtures", "reserves_files").to_s) }
  let(:collector) { instance_double MusicImportService::RecordingCollector }
  let(:logger) { instance_double Logger }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(collector).to receive(:recordings).and_return(
      [MusicImportService::RecordingCollector::MRRecording.new(14, "cd-9455", ["borris"], [], ["1791261"]),
       MusicImportService::RecordingCollector::MRRecording.new(15, "cd-431v1", ["mus204", "mus549sb"], ["Symphonies nos. 55-69"], ["2547641", "2686069"]),
       MusicImportService::RecordingCollector::MRRecording.new(3223, "x-mus257rakha", [], [], []),
       MusicImportService::RecordingCollector::MRRecording.new(3014, nil, [], [], [])]
    )
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
      expect(csv).to eq("id,call,courses,titles,bibs,duplicate,recommended_bib,final_bib\n" \
        "15,cd-431v1,\"[\"\"mus204\"\", \"\"mus549sb\"\"]\",\"[\"\"Symphonies nos. 55-69\"\"]\",\"[\"\"2547641\"\", \"\"2686069\"\"]\",,\n")
    end
  end

  describe "#zero_bibs_csv" do
    it "populates the fields of the csv, one row per recording" do
      csv = importer.zero_bibs_csv
      expect(csv).to eq "id,call,courses,titles,bibs,duplicate,recommended_bib,final_bib\n3223,x-mus257rakha,[],[],[],,\n3014,,[],[],[],,\n"
    end
  end

  describe "#course_names_csv" do
    it "has 2 columns, populates the first with course names that we don't recognize as actual courses" do
      expect(importer.course_names_csv).to eq "course_name,collection_name\nborris,\n"
    end
  end

  describe "#ingest_course" do
    it "ingests all recordings that are a member of a course" do
      new_collector = instance_double(MusicImportService::RecordingCollector)
      allow(importer.recording_collector).to receive(:with_recordings_query).and_return(new_collector)
      stub_bibdata(bib_id: "123456")
      recording = MusicImportService::RecordingCollector::MRRecording.new(
        14,
        "cd-431v1",
        ["mus204", "mus549sb"],
        ["Symphonies nos. 55-69"],
        ["123456"]
      )
      audio_files = [
        MusicImportService::RecordingCollector::AudioFile.new(
          id: 54_204,
          selection_id: 15_929,
          file_path: "cd-1",
          file_name: "cd-1_1",
          file_note: "First File",
          entry_id: "blabla",
          selection_title: "My Selection",
          selection_alt_title: nil,
          selection_note: "Paul Jacobs, piano"
        )
      ]
      allow(new_collector).to receive(:recordings).and_return([recording])
      allow(importer.recording_collector).to receive(:audio_files).with(recording).and_return(audio_files)

      output = importer.ingest_course("MUS-301")
      expect(output.length).to eq 1
      expect(output.first).to be_a ScannedResource
    end
  end
  describe "#ingest_recording" do
    it "ingests a recording and its audio files" do
      stub_bibdata(bib_id: "123456")
      recording = MusicImportService::RecordingCollector::MRRecording.new(
        14,
        "cd-431v1",
        ["mus204", "mus549sb"],
        ["Symphonies nos. 55-69"],
        ["123456"]
      )
      audio_files = [
        MusicImportService::RecordingCollector::AudioFile.new(
          id: 54_204,
          selection_id: 15_929,
          file_path: "cd-1",
          file_name: "cd-1_1.ra",
          file_note: "First File",
          entry_id: "blabla",
          selection_title: "My Selection",
          selection_alt_title: nil,
          selection_note: "Paul Jacobs, piano"
        )
      ]
      allow(importer.recording_collector).to receive(:audio_files).with(recording).and_return(audio_files)

      output = importer.ingest_recording(recording)
      expect(output).to be_a ScannedResource
      expect(output.local_identifier).to eq [14]
      members = Wayfinder.for(output).members

      expect(members.length).to eq 1
      expect(members.first.title).to eq ["First File"]
      expect(members.first.original_file.original_filename).to eq ["cd-1_1.wav"]

      playlists = Wayfinder.for(output).playlists

      expect(playlists.length).to eq 1
      expect(playlists.first.member_ids.length).to eq 1
      expect(playlists.first.title).to eq ["My Selection"]
    end
    context "when the files are missing" do
      it "doesn't create it and logs an error" do
        stub_bibdata(bib_id: "123456")
        recording = MusicImportService::RecordingCollector::MRRecording.new(
          14,
          "cd-431v1",
          ["mus204", "mus549sb"],
          ["Symphonies nos. 55-69"],
          ["123456"]
        )
        audio_files = [
          MusicImportService::RecordingCollector::AudioFile.new(
            id: 54_204,
            selection_id: 15_929,
            file_path: "cd-1",
            file_name: "cd-1_2",
            file_note: "First File",
            entry_id: "blabla",
            selection_title: "My Selection",
            selection_alt_title: nil,
            selection_note: "Paul Jacobs, piano"
          )
        ]
        allow(importer.recording_collector).to receive(:audio_files).with(recording).and_return(audio_files)

        output = importer.ingest_recording(recording)
        expect(output).to eq nil
        expect(logger).to have_received(:warn).with("Unable to ingest recording 14 - there are no files associated or the files are missing from disk.")
      end
    end
    context "when one file is missing" do
      it "creates it, but logs a warning that a file was missing" do
        stub_bibdata(bib_id: "123456")
        recording = MusicImportService::RecordingCollector::MRRecording.new(
          14,
          "cd-431v1",
          ["mus204", "mus549sb"],
          ["Symphonies nos. 55-69"],
          ["123456"]
        )
        audio_files = [
          MusicImportService::RecordingCollector::AudioFile.new(
            id: 54_204,
            selection_id: 15_929,
            file_path: "cd-1",
            file_name: "cd-1_1",
            file_note: "First File",
            entry_id: "blabla",
            selection_title: "My Selection",
            selection_alt_title: nil,
            selection_note: "Paul Jacobs, piano"
          ),
          MusicImportService::RecordingCollector::AudioFile.new(
            id: 54_205,
            selection_id: 15_929,
            file_path: "cd-1",
            file_name: "cd-1_2",
            file_note: "First File",
            entry_id: "blabla",
            selection_title: "My Selection",
            selection_alt_title: nil,
            selection_note: "Paul Jacobs, piano"
          )
        ]
        allow(importer.recording_collector).to receive(:audio_files).with(recording).and_return(audio_files)

        output = importer.ingest_recording(recording)
        expect(output).to be_a ScannedResource
        expect(output.member_ids.length).to eq 1
        expect(logger).to have_received(:warn).with("Unable to find AudioFile 54205 at location #{importer.file_root}/cd-1/cd-1_2.*")
      end
    end
  end

  def music_fixtures
    [{ "idRecording" => 14, "CallNo" => "cd-9455", "CourseNo" => "borris" },
     { "idRecording" => 15, "CallNo" => "cd-431v1", "CourseNo" => "mus204", "RecTitle" => "Symphonies nos. 55-69" },
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
