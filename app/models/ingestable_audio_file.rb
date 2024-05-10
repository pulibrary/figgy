# frozen_string_literal: true
# Decorates the Pathname with some convenience parsing methods
# Provides methods needed by FileMetadata.for
class IngestableAudioFile
  attr_reader :path

  def initialize(path:)
    @path = path
  end

  def original_filename
    path.split.last
  end

  def mime_type
    if preservation_file? || intermediate?
      "audio/x-wav"
    else
      "audio/mpeg"
    end
  end
  alias content_type mime_type

  def use
    if preservation_file?
      ::PcdmUse::PreservationFile
    elsif intermediate?
      ::PcdmUse::IntermediateFile
    elsif access?
      ::PcdmUse::ServiceFile
    end
  end

  def preservation_file?
    path.to_s.end_with?("_pm.wav")
  end

  def intermediate?
    path.to_s.end_with?("_i.wav")
  end

  def access?
    path.to_s.end_with?("_a.mp3")
  end

  def barcode_with_side
    @barcode_with_side ||= ArchivalMediaBagParser::BARCODE_WITH_SIDE_REGEX.match(original_filename.to_s)[1]
  end

  def is_a_part?
    part_match = ArchivalMediaBagParser::BARCODE_WITH_SIDE_AND_PART_REGEX.match(original_filename.to_s)
    return false if part_match.nil?
    @barcode_with_side_and_part = part_match.captures.first
    true
  end

  def barcode_with_side_and_part
    return @barcode_with_side_and_part if is_a_part?
    barcode_with_side
  end

  def barcode
    @barcode ||= barcode_with_side.split("_").first
  end

  def side
    @side ||= barcode_with_side.split("_").last
  end

  def part
    return unless is_a_part?
    @part ||= barcode_with_side_and_part.split("_").last
  end
end
