# frozen_string_literal: true
class Dspace::Bitstream
  attr_reader :data
  def initialize(data)
    @data = data
  end

  def title
    description.presence || name_no_extension
  end

  def ark
    nil
  end

  def handle
    nil
  end

  def id
    data["id"]
  end

  def name
    Array.wrap(data["name"]).first
  end

  def filename
    name.tr("/", "-")
  end

  def extension
    Pathname.new(filename).extname
  end

  def name_no_extension
    Pathname.new(filename).sub_ext("").to_s
  end

  def retrieve_link
    data["retrieveLink"]
  end

  def description
    data["description"]
  end

  def folder_name
    description.to_s.gsub(/[\/\[\]]/, "-")[0..49].strip.presence || name_no_extension
  end

  def sequence_id
    # Zero pad so it sorts.
    data["sequenceId"].to_s.rjust(3, "0")
  end

  def original?
    data["bundleName"] == "ORIGINAL"
  end
end
