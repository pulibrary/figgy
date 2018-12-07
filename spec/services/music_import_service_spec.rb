# frozen_string_literal: true
require "rails_helper"

RSpec.describe MusicImportService do
  let(:importer) { described_class.new(recording_collector: collector, logger: logger) }
  let(:collector) { instance_double MusicImportService::RecordingCollector }
  let(:logger) { instance_double Logger }

  before do
    allow(logger).to receive(:info)
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
