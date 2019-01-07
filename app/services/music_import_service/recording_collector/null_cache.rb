# frozen_string_literal: true
class MusicImportService::RecordingCollector
  class NullCache
    def self.fetch(_file, default = nil)
      if block_given?
        yield
      else
        default
      end
    end

    def self.store(_file, value)
      value
    end
  end
end
