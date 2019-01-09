# frozen_string_literal: true
require "csv"

# A service class to run an import of music reserves and performance recording
#   objects from a sql server database into figgy
class MusicImportService
  attr_reader :recording_collector, :logger, :file_root
  delegate :recordings, to: :recording_collector
  def initialize(recording_collector:, logger:, file_root:)
    @recording_collector = recording_collector
    @logger = logger
    @file_root = file_root
  end

  # yes there will be a #run method but the first step is the call number report
  def bibid_report
    suspected_playlists, real_recordings = recordings.partition { |rec| rec.call&.starts_with? "x-" }
    numbered_courses, rest = real_recordings.partition { |rec| rec.courses.any? { |course| numbered_course_name?(course) } }
    empty_courses, other_courses = rest.partition { |rec| rec.courses.empty? }

    log_multiple_bibs(real_recordings)
    log_missing_bibs(recordings: suspected_playlists, prefix: "Suspected playlist / no bibs")
    log_missing_bibs(recordings: numbered_courses, prefix: "Numbered course / no bibs")
    log_missing_bibs(recordings: other_courses, prefix: "Other course / no bibs")

    logger.info "Report Summary"
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(suspected_playlists)} of #{suspected_playlists.count} recordings (suspected playlists) " \
      "where call number starts with 'x-' (#{percent_empty(suspected_playlists)}%)"
    logger.info "Removed suspected playlists from remaining stats"
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(real_recordings)} of #{real_recordings.count} recordings (#{percent_empty(real_recordings)}%)"
    bad_recordings = recordings.select { |x| x.bibs.length > 1 }
    found_ids = bad_recordings.select { |x| x.recommended_bib.present? }
    logger.info "Found recommended bib for #{found_ids.length} of #{bad_recordings.length} records with multiple bib ids"
    logger.info "--------------"
    logger.info "Bib ids found in #{number_empty(numbered_courses)} of #{numbered_courses.count} recordings with numbered course names (#{percent_empty(numbered_courses)}%)"
    logger.info "Bib ids found in #{number_empty(other_courses)} of #{other_courses.count} recordings with other course names (#{percent_empty(other_courses)}%)"
    logger.info "#{empty_courses.count} recordings not in any course"
  end

  # return a CSV of recordings where we got more than one bib and no recommended_bib
  def extra_bibs_csv
    records = recordings.select { |x| x.bibs.length > 1 && x.recommended_bib.blank? }
    generate_csv(records)
  end

  def zero_bibs_csv
    records = recordings.select { |x| x.bibs.length.zero? }
    generate_csv(records)
  end

  def course_names_csv
    course_names = recordings.map(&:courses).flatten.uniq.reject { |x| numbered_course_name?(x) }
    return if course_names.empty?

    CSV.generate(headers: true) do |csv|
      csv << %w[course_name collection_name]
      course_names.each do |cn|
        csv << { "course_name" => cn }
      end
    end
  end

  def ingest_course(course)
    temp_recording_collector = recording_collector.with_recordings_query(course_recordings_query(course))
    temp_recording_collector.recordings.map do |recording|
      ingest_recording(recording)
    end
  end

  def course_recordings_query(course)
    "select R.idRecording, R.CallNo, R.RecTitle, C.CourseNo from Recordings R " \
      "left join Selections S on S.idRecording=R.idRecording " \
      "left join jSelections jS on S.idSelection=jS.idSelection " \
      "left join Courses C on jS.idCourse=C.idCourse " \
      "WHERE C.CourseNo = '#{course}'"
  end

  def ingest_recording(recording)
    Importer.new(recording_collector: recording_collector, recording: recording, file_root: file_root, logger: logger).import!
  end

  class Importer
    attr_reader :recording_collector, :recording, :file_root, :logger
    delegate :id, to: :recording, prefix: true
    def initialize(recording_collector:, recording:, file_root:, logger:)
      @recording_collector = recording_collector
      @recording = recording
      @file_root = Pathname.new(file_root.to_s)
      @logger = logger
    end

    def import!
      if files.empty?
        logger.warn "Unable to ingest recording #{recording.id} - there are no files associated or the files are missing from disk."
        return nil
      end
      change_set.files = files
      output = nil
      selections_to_courses = recording_collector.courses_for_selections(audio_files.flat_map(&:selection_id).uniq).group_by { |x| x.id.to_s.to_i }
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        output = buffered_change_set_persister.save(change_set: change_set)
        members = Wayfinder.for(output).members
        audio_files.group_by(&:selection_id).each do |selection_id, selection_files|
          next if selection_files.empty?
          file_set_members = members.select do |member|
            selection_files.map(&:id).map(&:to_s).include?(member.local_identifier.first)
          end
          ids = file_set_members.map(&:id)
          playlist = Playlist.new(title: selection_files.first.selection_title, local_identifier: selection_id.to_s, part_of: selections_to_courses[selection_id]&.first&.course_nums)
          change_set = DynamicChangeSet.new(playlist).prepopulate!
          change_set.file_set_ids = ids
          buffered_change_set_persister.save(change_set: change_set)
        end
      end
      output
    end

    def change_set_persister
      ScannedResourcesController.change_set_persister
    end

    def resource
      @resource ||= ScannedResource.new(source_metadata_identifier: identifier, local_identifier: recording_id, part_of: recording.courses)
    end

    def change_set
      @change_set ||= RecordingChangeSet.new(resource).prepopulate!
    end

    def identifier
      recording.bibs.first
    end

    def audio_files
      @audio_files ||= recording_collector.audio_files(recording)
    end

    def files
      @files ||=
        begin
          new_files = []
          audio_files.each do |file|
            if file_path(file)
              new_files << file
            else
              logger.warn("Unable to find AudioFile #{file.id} at location #{file_root.join(file.file_path).join("#{file.file_name}.*")}")
            end
          end
          new_files.map do |file|
            file_path = file_path(file)
            IngestableFile.new(
              file_path: file_path,
              mime_type: "audio/x-wav",
              original_filename: File.basename(file_path),
              container_attributes: {
                title: file.file_note,
                local_identifier: file.id.to_s
              }
            )
          end
        end
    end

    def file_path(file)
      path = file_root.join(file.file_path)
      file_name = File.basename(file.file_name, File.extname(file.file_name))
      Dir.glob(path.join("*")).find do |inner_path|
        File.basename(inner_path, ".*") == file_name
      end
    end
  end

  private

    def generate_csv(records)
      return if records.empty?

      CSV.generate(headers: true) do |csv|
        headings = MusicImportService::RecordingCollector::MRRecording.members.map(&:to_s) << "final_bib"
        csv << headings
        records.each do |record|
          csv << record.entries
        end
      end
    end

    def numbered_course_name?(cn)
      cn.match?(/^[a-zA-Z]{3}\d+.*$/)
    end

    def number_empty(recordings)
      recordings.reject { |rec| rec.bibs.empty? }.count
    end

    def percent_empty(recordings)
      (number_empty(recordings) / recordings.count.to_f * 100).to_i
    end

    def log_multiple_bibs(recordings)
      recordings.select { |rec| rec.bibs.count > 1 }.each do |rec|
        logger.info "multiple bibs id: #{rec.id}, bibs: #{rec.bibs}, call: #{rec.call}, courses: #{rec.courses}"
      end
    end

    def log_missing_bibs(recordings:, prefix:)
      missing, _present = recordings.partition { |rec| rec.bibs.empty? }
      missing.each do |rec|
        logger.info "#{prefix} id: #{rec.id}, call: #{rec.call}, title: #{rec.titles.first}, courses: #{rec.courses}"
      end
    end
end
