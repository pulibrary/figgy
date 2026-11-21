module Webdav
  # Byte sizes of IIIF derivative JPEGs, which only the image server knows.
  #
  # Clients need real sizes: macOS treats a 0-byte file as empty and won't
  # make a Quick Look thumbnail for it. So when a folder is listed, missing
  # sizes are fetched with parallel HEAD requests within a time budget, and
  # cached. A rendering only changes when its file does, and the cache key
  # includes the file's mtime, so cached sizes last a long time. Anything not
  # fetched in time is listed without a size and fills in on a later listing.
  # The HEAD requests also warm the image server's cache for the downloads
  # that follow.
  class DerivativeSizes
    CACHE_TTL = 30.days
    BUDGET = 3.seconds
    CONCURRENCY = 8

    # @param entries [Array<Entry>] derivative entries
    # @param fetch [Boolean] false to only use sizes already cached
    # @return [Hash{String => Integer}] size by derivative URL
    def self.for(entries, fetch: true)
      new(entries).sizes(fetch: fetch)
    end

    attr_reader :entries
    def initialize(entries)
      @entries = entries
    end

    def sizes(fetch: true)
      return {} if entries.empty?
      keys = entries.to_h { |entry| [cache_key(entry), entry.derivative_url] }
      found = Rails.cache.read_multi(*keys.keys).transform_keys { |key| keys[key] }
      return found unless fetch
      missing = entries.map(&:derivative_url) - found.keys
      fetched = fetch_sizes(missing)
      entries.each do |entry|
        size = fetched[entry.derivative_url]
        Rails.cache.write(cache_key(entry), size, expires_in: CACHE_TTL) if size
      end
      found.merge(fetched)
    end

    private

      def cache_key(entry)
        "webdav/v1/derivative-size/#{Digest::SHA256.hexdigest(entry.derivative_url)}/#{entry.mtime.to_i}"
      end

      def fetch_sizes(urls)
        return {} if urls.empty?
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + BUDGET
        queue = Queue.new
        urls.each { |url| queue << url }
        results = Concurrent::Hash.new
        Array.new([CONCURRENCY, urls.size].min) do
          Thread.new do
            until Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
              url = begin
                      queue.pop(true)
              rescue ThreadError
                      break
              end
              size = head_size(url, deadline)
              results[url] = size if size
            end
          end
        end.each(&:join)
        results.to_h
      end

      def head_size(url, deadline)
        remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
        return if remaining <= 0
        response = connection.head(url) { |req| req.options.timeout = remaining }
        return unless response.success?
        length = response.headers["content-length"].to_i
        return length if length.positive?
        # Some image servers (e.g. Riiif) leave Content-Length off HEAD
        # responses, so fall back to rendering it and counting.
        response = connection.get(url) { |req| req.options.timeout = remaining }
        response.body.bytesize if response.success? && response.body.present?
      rescue StandardError => e # A missing size must never break a listing.
        Rails.logger.warn("WebDAV: couldn't size #{url}: #{e.class}: #{e.message}")
        nil
      end

      def connection
        @connection ||= Faraday.new
      end
  end
end
