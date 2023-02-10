# frozen_string_literal: true
class BulkIngestService::BulkFilePathConverter
  class BulkIngestFile
    attr_reader :file_path, :path_converter, :previous
    delegate :parent_resource, :file_paths, :preserve_file_names, to: :path_converter
    def initialize(file_path:, path_converter:,
                   previous:)
      @file_path = file_path
      @path_converter = path_converter
      @previous = previous
    end

    def to_ingestable_file
      IngestableFile.new(
        file_path: file_path,
        mime_type: mime_type.content_type,
        original_filename: basename,
        copy_before_ingest: true,
        container_attributes: {
          title: file_title,
          service_targets: service_targets
        }
      )
    end

    def file_title
      if title_with_extension?
        basename
      elsif title_without_extension?
        basename.gsub(File.extname(basename), "")
        # Add cropped title if there's cropped/uncropped
      elsif parent_title_with_cropped_suffix?
        "#{parent_resource.title.first} (Cropped)"
      elsif inherit_parent_title?
        parent_resource.title.map(&:to_s)
      else
        count.to_s
      end
    end

    def title_with_extension?
      preserved_file_name_mime_types.include?(mime_type.content_type)
    end

    def title_without_extension?
      preserve_file_names
    end

    def parent_title_with_cropped_suffix?
      cropped_title?
    end

    def inherit_parent_title?
      raster_resource_parent? || scanned_map_parent?
    end

    def counted_title?
      if title_with_extension? || title_without_extension? || parent_title_with_cropped_suffix? || inherit_parent_title?
        false
      else
        true
      end
    end

    # If we're a counted (numerical) title, increase the count from the previous node.
    # Otherwise don't.
    def count
      @count ||=
        begin
          start_count = previous.try(:count) || 0
          if counted_title?
            start_count + 1
          else
            start_count
          end
        end
    end

    def cropped_title?
      raster_resource_parent? && mosaic_service_target? && file_paths.size > 1
    end

    # Mosaic target if creating a raster and there's either one file or the
    # given file has _cropped in the name.
    def mosaic_service_target?
      return false unless raster_resource_parent?
      return true if file_paths.length == 1
      basename.to_s.include?("_cropped")
    end

    def service_targets
      return unless raster_resource_parent? && mosaic_service_target?
      "tiles"
    end

    def mime_type
      mime_types = MIME::Types.type_for(basename)
      # New mime-types gem prefers audio/wav, but all our code is set up for
      # audio/x-wav, so do this so it picks x-wav.
      preferred_mime_type = mime_types.find do |mime_type|
        preserved_file_name_mime_types.include?(mime_type.to_s)
      end
      preferred_mime_type || mime_types.first
    end

    def basename
      @basename ||= File.basename(file_path)
    end

    def scanned_map_parent?
      parent_resource.is_a?(ScannedMap)
    end

    def raster_resource_parent?
      parent_resource.is_a?(RasterResource)
    end

    def preserved_file_name_mime_types
      ["audio/x-wav", "application/json"]
    end
  end
end
