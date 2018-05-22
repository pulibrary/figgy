# frozen_string_literal: true
# Decorates the Pathname with some convenience parsing methods
# Provides methods needed by FileMetadata.for
class IngestableAudioFile
  attr_reader :path, :barcode_with_part

  def initialize(path:)
    @path = path
  end

  def original_filename
    path.split.last
  end

  def mime_type
    if master? || intermediate?
      "audio/wav"
    else
      "audio/mpeg"
    end
  end
  alias content_type mime_type

  def use
    if master?
      Valkyrie::Vocab::PCDMUse.PreservationMasterFile
    elsif intermediate?
      Valkyrie::Vocab::PCDMUse.IntermediateFile
    elsif access?
      Valkyrie::Vocab::PCDMUse.ServiceFile
    end
  end

  def master?
    path.to_s.end_with?("_pm.wav")
  end

  def intermediate?
    path.to_s.end_with?("_i.wav")
  end

  def access?
    path.to_s.end_with?("_a.mp3")
  end

  def barcode_with_part
    @barcode_with_part ||= ArchivalMediaBagParser::BARCODE_WITH_PART_REGEX.match(original_filename.to_s)[1]
  end
end
