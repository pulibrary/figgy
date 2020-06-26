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
    attr_reader :recording_collector, :recording, :file_root, :logger, :processing_dependents
    delegate :id, to: :recording, prefix: true
    def initialize(recording_collector:, recording:, file_root:, logger:, change_set_persister: nil, processing_dependents: false)
      @recording_collector = recording_collector
      @recording = recording
      @file_root = Pathname.new(file_root.to_s)
      @logger = logger
      @change_set_persister = change_set_persister
      @processing_dependents = processing_dependents
    end

    def import!
      if (found_recording = find_recording)
        logger.warn "Recording #{recording.id} is already ingested - skipping"
        return update_courses(found_recording)
      end
      if files.empty?
        logger.warn "Unable to ingest recording #{recording.id} - there are no files associated or the files are missing from disk."
        return nil
      end
      # Currently trying to ingest a fake playlist.
      if recording_is_fake?
        ingest_fake_playlist
      else
        ingest_recording
      end
    end

    def update_courses(found_recording)
      found_recording.part_of = (Array.wrap(found_recording.part_of) + recording.courses).uniq
      change_set_persister.persister.save(resource: found_recording)
    end

    def recording_is_fake?
      return false unless all_audio_files.length != audio_files.length
      return false unless identifier.blank?
      return false if recording.call.downcase.start_with?("cd")
      Array.wrap(recording.titles).first.downcase.include?("playlist") || recording.call.downcase.include?("playlist")
    end

    def find_recording
      query_service.custom_queries.find_by_property(property: :local_identifier, value: recording.id.to_s).find do |x|
        ChangeSet.for(x).is_a?(RecordingChangeSet)
      end
    end

    def dependent_importer(dependent, change_set_persister)
      self.class.new(
        recording_collector: recording_collector,
        recording: dependent,
        file_root: file_root,
        logger: logger,
        change_set_persister: change_set_persister,
        processing_dependents: true
      )
    end

    # "Fake" playlists are Recordings which contain duplicated AudioFiles for
    # the purpose of providing week-by-week playlists from multiple recordings
    # in the old system, which wasn't possible, but is now.
    def ingest_fake_playlist
      logger.info "Detected that recording #{recording.id} is a fake playlist. Ingesting it appropriately."
      # Sometimes an audio file for a fake playlist is also in another fake
      # playlist (in addition to the real recording), so the system sees it as a
      # "dependent." If it tries to ingest that second fake playlist it'll get
      # into an infinite loop of trying to import fake playlists. So, just skip
      # the second fake playlist-as-dependent, and ingest it on its own if it's
      # part of a course.
      if processing_dependents
        logger.info "Refusing to ingest #{recording.id} while ingesting another fake playlist."
        return
      end
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        # Import dependents
        recording_collector.with_recordings_query(recording_collector.dependent_recordings_query(dependent_ids)).recordings.each do |rec|
          dependent_importer(rec, buffered_change_set_persister).import!
        end
        # Create a playlist for each selection
        selections_to_courses = recording_collector.courses_for_selections(audio_files.flat_map(&:selection_id).uniq).group_by { |x| x.id.to_s.to_i }
        audio_files.group_by(&:selection_id).each do |selection_id, selection_files|
          next if selection_files.empty?
          playlist = Playlist.new(title: selection_files.first.selection_title, local_identifier: selection_id.to_s, part_of: selections_to_courses[selection_id]&.first&.course_nums)
          # Find previously imported dependent file sets
          file_set_ids = selection_files.map do |file|
            {
              query_service.custom_queries.find_by_property(property: :local_identifier, value: file.entry_id.to_s).first&.id => file.id
            }
          end.inject(&:merge).compact
          change_set = ChangeSet.for(playlist)
          change_set.file_set_ids = file_set_ids.keys
          output = buffered_change_set_persister.save(change_set: change_set)
          # Fix labels
          members = Wayfinder.for(output).members
          possible_files = selection_files.group_by(&:id)
          members.each do |member|
            change_set = ChangeSet.for(member)
            file = Array.wrap(possible_files[file_set_ids[member.proxied_file_id]]).first
            change_set.label = file.file_note
            change_set.local_identifier = file.id.to_s
            buffered_change_set_persister.save(change_set: change_set)
          end
        end
      end
    end

    def dependent_ids
      @dependent_ids ||=
        begin
          all_audio_files.select do |audio_file|
            audio_file.recording_id != recording.id && audio_file.entry_id.present?
          end.map(&:recording_id)
        end
    end

    def ingest_recording
      logger.info "Ingesting #{recording.id}: #{recording.titles}"
      output = nil
      recording_change_set.files = files
      if in_performance_course?
        collections = find_or_create_collections
        recording_change_set.member_of_collection_ids = collections.map(&:id)
      end
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        output = buffered_change_set_persister.save(change_set: recording_change_set)
        if in_non_performance_course?
          create_playlists(output, buffered_change_set_persister)
        else
          output = create_logical_structure(output, buffered_change_set_persister)
        end
      end
      output
    end

    def in_performance_course?
      # check intersection
      (recording.courses & course_names_table.keys).present?
    end

    def in_non_performance_course?
      recording.courses.each do |course|
        return true unless course_names_table.keys.include?(course)
      end
      false
    end

    def course_names_table
      @course_names_table ||=
        begin
          lookup_table = {}
          file = Rails.root.join("config", "audio_reserves", "recordings_course_names_massaged.csv")
          CSV.open(file, headers: true).each do |row|
            h = row.to_h
            lookup_table[h["course_name"]] = h["collection_name"]
          end
          lookup_table
        end
    end

    def find_or_create_collections
      performance_courses = recording.courses.map do |course|
        [course, course_names_table[course]] if course_names_table[course]
      end.compact
      performance_courses.map do |pair|
        existing = query_service.custom_queries.find_by_property(property: :title, value: pair[1]).select { |c| c.is_a? Collection }
        if existing.present?
          existing.first
        else
          collection = Collection.new(slug: pair[0], title: pair[1])
          change_set_persister.save(change_set: ChangeSet.for(collection))
        end
      end
    end

    def create_playlists(output, buffered_change_set_persister)
      selections_to_courses = recording_collector.courses_for_selections(audio_files.flat_map(&:selection_id).uniq).group_by { |x| x.id.to_s.to_i }
      members = Wayfinder.for(output).members
      audio_files.group_by(&:selection_id).each do |selection_id, selection_files|
        next if selection_files.empty? || selection_files.length < 2
        file_set_members = members.select do |member|
          selection_files.map(&:id).map(&:to_s).include?(member.local_identifier.first)
        end
        ids = file_set_members.map(&:id)
        playlist = Playlist.new(title: selection_files.first.selection_title, local_identifier: selection_id.to_s, part_of: selections_to_courses[selection_id]&.first&.course_nums)
        change_set = ChangeSet.for(playlist)
        change_set.file_set_ids = ids
        buffered_change_set_persister.save(change_set: change_set)
      end
    end

    def create_logical_structure(output, buffered_change_set_persister)
      selection_ids = audio_files.flat_map(&:selection_id).uniq.compact
      return output unless selection_ids.present?
      selections_to_courses = recording_collector.courses_for_selections(selection_ids).group_by { |x| Array.wrap(x.class_sort).first }
      audio_files_by_date = Hash[
        selections_to_courses.map { |date, selections| [date, selections.flat_map { |selection| audio_files.select { |audio_file| audio_file.selection_id == selection.id.to_s.to_i } }] }
      ]
      members = Wayfinder.for(output).members
      structure = audio_files_by_date.each_with_object([]) do |date_audio_files, st|
        date = date_audio_files.first
        audio_files = date_audio_files.last
        nodes = audio_files.group_by(&:selection_title).flat_map do |title, selection_audio_files|
          audio_file_nodes = selection_audio_files.map do |audio_file|
            file_set_id = members.find { |member| member.local_identifier.first == audio_file.id.to_s }.try(&:id)
            { proxy: file_set_id }
          end
          if title.present?
            audio_file_nodes = [{ label: title, nodes: audio_file_nodes }]
          end
          audio_file_nodes
        end
        st << { nodes: nodes, label: date }
      end
      change_set = ChangeSet.for(output)
      change_set.logical_structure[0].label = "By Date"
      change_set.logical_structure[0].nodes += structure
      buffered_change_set_persister.save(change_set: change_set)
    end

    def change_set_persister
      @change_set_persister ||= ScannedResourcesController.change_set_persister
    end

    def query_service
      @query_service ||= change_set_persister.query_service
    end

    def resource
      @resource ||= begin
        existing_resource = find_or_build_resource_by_identifier(identifier: identifier)
        existing_resource.local_identifier = Array.wrap(existing_resource.local_identifier) + [recording_id.to_s]
        existing_resource.part_of = Array.wrap(existing_resource.part_of) + recording.courses
        existing_resource.title = Array.wrap(existing_resource.title).first || Array.wrap(recording.titles).first
        existing_resource.source_metadata_identifier = identifier
        existing_resource
      end
    end

    def find_or_build_resource_by_identifier(identifier:)
      return ScannedResource.new if identifier.blank?
      query_service.custom_queries.find_by_property(property: :source_metadata_identifier, value: identifier).first || ScannedResource.new
    end

    def recording_change_set
      @recording_change_set ||= RecordingChangeSet.new(resource)
    end

    def identifier
      recording.bibs.first || recording.recommended_bib
    end

    def all_audio_files
      @all_audio_files ||= recording_collector.audio_files(recording)
    end

    def audio_files
      @audio_files ||= all_audio_files.select do |file|
        file.recording_id.to_s == recording.id.to_s
      end.uniq(&:id)
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
                local_identifier: [file.id.to_s, file.entry_id.to_s]
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
