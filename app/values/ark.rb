# frozen_string_literal: true

class Ark
  attr_reader :ark

  def initialize(ark)
    @ark = Array.wrap(ark).first.gsub("http://arks.princeton.edu/", "") unless Array.wrap(ark).first.nil?
  end

  def identifier
    ark.gsub("http://arks.princeton.edu", "")
  end

  def uri
    "http://arks.princeton.edu/#{ark}"
  end

  # remove any path past the shoulder and blade, e.g. `/pdf`
  def minimal_identifier
    identifier.split("/")[0..2].join("/")
  end
end
