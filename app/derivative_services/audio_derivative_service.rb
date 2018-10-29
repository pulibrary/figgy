# frozen_string_literal: true
class AudioDerivativeService
  class Factory
    attr_reader :change_set_persister
    delegate :metadata_adapter, :storage_adapter, to: :change_set_persister
    delegate :query_service, to: :metadata_adapter
    def initialize(change_set_persister:)
      @change_set_persister = change_set_persister
    end

    def new(change_set)
      AudioDerivativeService.new(change_set: change_set, change_set_persister: change_set_persister, target_file: target_file(change_set.resource))
    end

    def target_file(resource)
      resource.original_file
    end
  end

  attr_reader :change_set, :change_set_persister, :target_file
  delegate :mime_type, to: :target_file
  delegate :resource, to: :change_set
  delegate :storage_adapter, to: :change_set_persister
  def initialize(change_set:, change_set_persister:, target_file:)
    @change_set = change_set
    @change_set_persister = change_set_persister
    @target_file = target_file
  end

  def valid?
    ["audio/x-wav"].include?(mime_type.first)
  end

  def create_derivatives
    _stdout, _stderr, status = Open3.capture3("ffmpeg", "-y", "-i", file_object.disk_path.to_s, "-codec:a", "libmp3lame", temporary_output.path.to_s)
    return unless status.success?
    change_set.files = [build_file]
    change_set_persister.buffer_into_index do |buffered_persister|
      buffered_persister.save(change_set: change_set)
    end
  end

  def cleanup_derivatives
    deleted_files = []
    audio_derivatives = resource.file_metadata.select { |file| file.derivative? && file.mime_type.include?("audio/mp3") }
    audio_derivatives.each do |file|
      storage_adapter.delete(id: file.file_identifiers.first)
      deleted_files << file.id
    end
    cleanup_derivative_metadata(derivatives: deleted_files)
  end

  private

    def build_file
      IngestableFile.new(
        file_path: temporary_output.path,
        mime_type: "audio/mp3",
        original_filename: "access_file.mp3",
        use: Valkyrie::Vocab::PCDMUse.ServiceFile,
        copyable: true
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
      updated_change_set = DynamicChangeSet.new(resource)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end

    def temporary_output
      @temporary_file ||= Tempfile.new(["tempfile", ".mp3"])
    end
end
