# frozen_string_literal: true
class BulkIngestService
  # Converts file paths to IngestableFiles to attach to a parent.
  class BulkFilePathConverter
    attr_reader :file_paths, :parent_resource, :preserve_file_names, :caption_files
    def initialize(file_paths:, parent_resource:, preserve_file_names: false, caption_files: nil)
      @file_paths = file_paths
      @parent_resource = parent_resource
      @preserve_file_names = preserve_file_names
      @caption_files = caption_files
    end

    # @return [Array<IngestableFile>]
    def to_a
      return ingestable_files_with_captions if caption_files.present?
      ingestable_files
    end

    def ingestable_files
      previous = nil
      file_paths.map do |f|
        previous = BulkIngestFile.new(
          file_path: f,
          path_converter: self,
          previous: previous
        )
        previous.to_ingestable_file
      end
    end

    def ingestable_files_with_captions
      ingestable_files.map do |f|
        next unless (vtt = matching_vtt(f))
        vtt_path = Pathname(vtt)
        f.container_attributes[:files] = [
          IngestableFile.new(
            file_path: vtt_path,
            mime_type: "text/vtt",
            original_filename: vtt_path.basename.to_s,
            use: Valkyrie::Vocab::PCDMUse.Caption,
            node_attributes: {
              caption_language: infer_language(vtt_path)
            }
          )
        ]
        f
      end
    end

    def matching_vtt(file)
      caption_files.find do |cf|
        cf.starts_with?(file.file_path.sub_ext("").to_s)
      end
    end

    def infer_language(vtt_path)
      vtt_path.basename.sub_ext("").to_s.split("--")[-1]
    end
  end
end
