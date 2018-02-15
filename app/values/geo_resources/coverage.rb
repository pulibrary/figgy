# frozen_string_literal: true
module GeoResources
  class Coverage
    class ParseError < StandardError; end
    class InvalidGeometryError < StandardError; end

    attr_reader :n, :e, :s, :w

    def self.parse(str)
      n = parse_coordinate(str, /northlimit=([\.\d\-]+);/)
      e = parse_coordinate(str, /eastlimit=([\.\d\-]+);/)
      s = parse_coordinate(str, /southlimit=([\.\d\-]+);/)
      w = parse_coordinate(str, /westlimit=([\.\d\-]+);/)
      raise ParseError, str if n.nil? || e.nil? || s.nil? || w.nil?
      new(n, e, s, w)
    rescue
      nil
    end

    def self.parse_coordinate(str, regex)
      Regexp.last_match(1).to_f if str =~ regex
    end

    def initialize(n, e, s, w)
      raise InvalidGeometryError, "n=#{n} < s=#{s}" if n.to_f < s.to_f
      raise InvalidGeometryError, "e=#{e} < w=#{w}" if e.to_f < w.to_f
      @n = n
      @e = e
      @s = s
      @w = w
    end

    def to_s
      "northlimit=#{n}; eastlimit=#{e}; southlimit=#{s}; westlimit=#{w}; units=degrees; projection=EPSG:4326"
    end
  end
end
