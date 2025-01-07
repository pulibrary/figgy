# frozen_string_literal: true
# Generates MP3s from uploaded WAV files.
# @note This will not generate files for any Resource that stores its primary
# file as a PreservationFile instead of an original file.
class AvDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(id:)
      AvDerivativeService.new(id: id, change_set_persister: change_set_persister)
    end
  end

  attr_reader :change_set_persister, :id
  delegate :mime_type, to: :target_file
  delegate :storage_adapter, :query_service, to: :change_set_persister
  def initialize(id:, change_set_persister:)
    @id = id
    @change_set_persister = change_set_persister
  end

  def resource
    @resource ||= query_service.find_by(id: id)
  end

  # Don't use primary_file here - use original_file if there is one, otherwise
  # intermediate_file. Derivatives should come from the smaller crafted
  # intermediate file, not the huge preservation file, which is what
  # primary_file would point to.
  def target_file
    resource.original_file || resource.intermediate_files.first
  end

  def change_set
    @change_set ||= ChangeSet.for(resource)
  end

  def valid?
    target_file && MediainfoCharacterizationService.supported_formats.include?(mime_type.first)
  end

  def create_derivatives
    Dir.mktmpdir do |dir|
      dir = Pathname.new(dir)
      output, built_files = generate_hls_derivatives(dir)
      break unless built_files
      generate_hls_playlist(output, dir, built_files)
    end
  end

  def generate_hls_playlist(output, dir, built_files)
    hls_file = dir.join("hls.m3u8")
    content = File.read(hls_file)
    built_files.each do |file, id|
      content.gsub!(file, helper.download_url(resource.id, id))
    end
    File.open(hls_file, "w") do |f|
      f.puts content
    end
    change_set = ChangeSet.for(output)
    change_set.files = [build_file(hls_file, filename: "hls.m3u8")]
    change_set_persister.buffer_into_index do |buffered_persister|
      @resource = buffered_persister.save(change_set: change_set)
    end
  end

  # rubocop:disable Metrics/MethodLength
  def generate_hls_derivatives(dir)
    _stdout, _stderr, status =
      Open3.capture3("ffmpeg", "-y",
                     "-i", file_object.disk_path.to_s,
                     "-f", "hls", # HTTP Live Streaming output format
                     "-hls_list_size", "0", # playlist will contain all entries
                     "-hls_time", "10", # segments are 10s in length
                     "-c:v", "libx264", # encode video with H.264
                     "-preset", "slow", # slow encoding for better compression
                     "-crf", "20", # video quality from 0-51
                     "-vf", "format=yuv420p", # needed for Firefox. See: https://trac.ffmpeg.org/wiki/Encode/H.264#Encodingfordumbplayers
                     "-movflags", "+faststart", # good option for web video
                     "-c:a", "aac", # encode audio with AAC
                     "-b:a", "160k", # audio bitrate
                     "-muxdelay", "0",
                     dir.join("hls.m3u8").to_s)
    return unless status.success?
    change_set.files = Dir[dir.join("*.ts")].map do |file|
      build_file(file, filename: Pathname.new(file).basename, partial: true)
    end
    output = nil
    change_set_persister.buffer_into_index do |buffered_persister|
      output = buffered_persister.save(change_set: change_set)
    end
    built_files = output.file_metadata.select(&:derivative_partial?).map do |file|
      { file.label.first => file.id }
    end.inject(&:merge)
    [output, built_files]
  end
  # rubocop:enable Metrics/MethodLength

  def helper
    @helper ||= ManifestBuilder::ManifestHelper.new
  end

  def cleanup_derivatives
    deleted_files = []
    av_derivatives = resource.file_metadata.select(&:av_derivative?)
    av_derivatives.each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end

  private

    def build_file(file, filename:, partial: false)
      IngestableFile.new(
        file_path: file.to_s,
        mime_type: partial ? "video/MP2T" : "application/x-mpegURL",
        original_filename: filename,
        use: partial ? ::PcdmUse::ServiceFilePartial : ::PcdmUse::ServiceFile,
        copy_before_ingest: true
      )
    end

    def file_object
      @file_object ||= Valkyrie::StorageAdapter.find_by(id: target_file.file_identifiers[0])
    end

    # This removes all Valkyrie::StorageAdapter::File member Objects from a given Resource (usually a FileSet)
    # Resources consistently store the membership using #file_metadata
    # A ChangeSet for the purged members is created and persisted
    def cleanup_derivative_metadata(derivatives:)
      resource.file_metadata = resource.file_metadata.reject { |file| derivatives.include?(file.id) }
      updated_change_set = ChangeSet.for(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
