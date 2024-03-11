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
        vtts = matching_vtts(f)
        next if vtts.blank?
        vtt_paths = vtts.map { |vtt| Pathname(vtt) }
        f.container_attributes[:files] = vtt_paths.map do |vtt_path|
          build_ingestable_vtt(vtt_path)
        end
        f
      end
    end

    def matching_vtts(file)
      caption_files.select do |cf|
        cf.starts_with?(file.file_path.sub_ext("").to_s)
      end
    end

    def build_ingestable_vtt(vtt_path)
      IngestableFile.new(
        file_path: vtt_path,
        mime_type: "text/vtt",
        original_filename: vtt_path.basename.to_s,
        use: Valkyrie::Vocab::PCDMUse.Caption,
        node_attributes: {
          caption_language: infer_language(vtt_path),
          original_language_caption: infer_original_language(vtt_path)
        }
      )
    end

    def infer_language(vtt_path)
      flag = vtt_path.basename.sub_ext("").to_s.split("--")[-1]
      entry_exists = ControlledVocabulary.for(:language).include?(flag)
      return flag if entry_exists
      "und" # ISO 639 code for "Undefined"
    end

    # @return [boolean] true if the second to last section of the filename
    # matches the original-language flag
    def infer_original_language(vtt_path)
      flag = vtt_path.basename.sub_ext("").to_s.split("--")[-2]
      flag == "original-language"
    end
  end
end
