module Webdav
  # A slice of the (folded, lowercased) title sort space: every title that
  # starts with `prefix` and whose next character's codepoint is in [lo, hi).
  #
  # These are the "letter" folders that make a few hundred thousand titles
  # browsable. A range with a big result count splits into child ranges, a
  # small one lists its resources directly. The folder name encodes the whole
  # range, so a range can be rebuilt from its last path segment alone.
  #
  # Ranges map straight to Solr range queries on `title_ssort`, so they work
  # without any reindexing.
  class TitleRange
    MAX = 0x110000
    SEPARATOR = "–" # en dash
    # Starting splits for an open-ended range. Digits and Latin letters get
    # their own folders, other scripts are grouped by Unicode block. Each
    # boundary is the first lowercase letter of its script (Greek α, Cyrillic а,
    # Armenian ա, Hebrew א, Arabic ء, then Syriac, kana, CJK, Yi, Hangul).
    BOUNDARIES = (
      [0x00] + ("0".ord.."9".ord).to_a + [0x3a] + ("a".ord.."z".ord).to_a +
      [0x7b, 0x3b1, 0x430, 0x561, 0x5d0, 0x621, 0x700, 0x3041, 0x4e00, 0xa000, 0xac00, 0xd7b0, MAX]
    ).freeze
    BISECT_WAYS = 16
    # Characters that can't (or shouldn't) appear in a folder name.
    UNSAFE = %r{[\x00-\x20%/\\:\x7f#{SEPARATOR}]}

    attr_reader :prefix, :lo, :hi

    def self.root
      new(prefix: "", lo: 0, hi: MAX)
    end

    # Rebuild a range from a folder name.
    # @return [TitleRange, nil]
    def self.parse(name)
      left, right, extra = name.to_s.split(SEPARATOR, -1)
      return if extra || left.blank?
      left = decode(left)
      return new(prefix: left, lo: 0, hi: MAX) if right.nil?
      right = decode(right)
      return unless right.present? && left.length == right.length && left[0..-2] == right[0..-2]
      return unless left[-1].ord <= right[-1].ord
      new(prefix: left[0..-2], lo: left[-1].ord, hi: right[-1].ord + 1)
    rescue ArgumentError, Encoding::CompatibilityError
      nil
    end

    def self.encode(str)
      str.gsub(UNSAFE) { |c| c.bytes.map { |b| format("%%%02X", b) }.join }
    end

    def self.decode(str)
      decoded = str.gsub(/%[0-9A-F]{2}/) { |h| h[1..].hex.chr }.force_encoding(Encoding::UTF_8)
      raise ArgumentError, "invalid encoding" unless decoded.valid_encoding?
      decoded
    end

    def initialize(prefix:, lo:, hi:)
      lo = skip_surrogates(lo)
      hi = skip_surrogates(hi)
      # A range over exactly one character is the same as a longer prefix.
      if hi - lo == 1
        @prefix = prefix + lo.chr(Encoding::UTF_8)
        @lo = 0
        @hi = MAX
      else
        @prefix = prefix
        @lo = lo
        @hi = hi
      end
    end

    def open?
      lo.zero? && hi == MAX
    end

    def name
      return self.class.encode(prefix) if open?
      "#{self.class.encode(prefix + lo.chr(Encoding::UTF_8))}#{SEPARATOR}#{self.class.encode(prefix + (hi - 1).chr(Encoding::UTF_8))}"
    end

    def children
      bounds = if open?
                 BOUNDARIES
      else
                 step = [(hi - lo).fdiv(BISECT_WAYS).ceil, 1].max
                 [lo] + (lo + step...hi).step(step).map { |b| fold_stable(b, hi) } + [hi]
      end
      bounds.uniq.each_cons(2).map { |a, b| self.class.new(prefix: prefix, lo: a, hi: b) }
    end

    # @return [String, nil] a Solr filter query, nil if it would match everything
    def solr_filter
      return if prefix.empty? && open?
      lower = lo.zero? ? prefix : prefix + lo.chr(Encoding::UTF_8)
      upper = if hi < MAX
                quote(prefix + hi.chr(Encoding::UTF_8))
      elsif prefix.empty?
                "*"
      else
                quote(prefix[0..-2] + skip_surrogates(prefix[-1].ord + 1).chr(Encoding::UTF_8))
      end
      "title_ssort:[#{quote(lower)} TO #{upper}}"
    end

    private

      # Solr runs range endpoints through the field's ICU folding (lowercase,
      # NFKC, strip diacritics). A boundary character that folding changes
      # could land out of order and make sibling ranges overlap, so move each
      # split point forward to a character that folding leaves alone. Indexed
      # titles only contain those characters, so the ranges still cover every
      # title.
      def fold_stable(codepoint, limit)
        cp = skip_surrogates(codepoint)
        while cp < limit
          char = cp.chr(Encoding::UTF_8)
          return cp if char.unicode_normalize(:nfkd) == char && char.downcase(:fold) == char
          cp = skip_surrogates(cp + 1)
        end
        limit
      rescue RangeError, Encoding::CompatibilityError
        limit
      end

      def skip_surrogates(codepoint)
        codepoint.between?(0xd800, 0xdfff) ? 0xe000 : codepoint
      end

      def quote(str)
        %("#{str.gsub(/[\\"]/) { |c| "\\#{c}" }}")
      end
  end
end
