# frozen_string_literal: true

class JP2Creator
  attr_reader :filename
  def initialize(filename:)
    @filename = filename
  end

  def generate
    color_corrected_tiff = correct_color(filename)
    _stdout, stderr, status =
      Open3.capture3("opj_compress", "-i", color_corrected_tiff.path.to_s, "-o", temporary_output.path.to_s, "-t", "1024,1024", "-p", "RPCL", "-n", "8", "-r", "10")
    raise stderr unless status.success?
    temporary_output
  end

  def correct_color(filename)
    temp_file = Tempfile.new(["tempfile", ".tif"])
    file = MiniMagick::Image.open(filename)
    return File.open(filename) unless file["%[channels]"] != "gray"
    file.format "tiff"
    file.combine_options do |c|
      c.profile Hydra::Derivatives::Processors::Jpeg2kImage.srgb_profile_path
      c.type "truecolor"
    end
    file.write temp_file.path
    temp_file
  end

  def temporary_output
    @temporary_file ||= Tempfile.new(["intermediate_file", ".jp2"])
  end
end
