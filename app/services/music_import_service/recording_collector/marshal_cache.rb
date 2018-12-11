# frozen_string_literal: true
class MusicImportService::RecordingCollector
  class MarshalCache
    attr_reader :location
    def initialize(location)
      @location = Pathname.new(location)
    end

    def fetch(file, default = nil)
      if File.exist?(location.join(file))
        Marshal.load(File.open(location.join(file)))
      elsif block_given?
        results = yield
        store(file, results)
      else
        default
      end
    end

    def store(file, value)
      FileUtils.mkdir_p(location)
      File.open(location.join(file), "wb") do |f|
        f.puts Marshal.dump(value)
      end
      value
    end
  end
end
