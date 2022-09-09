# frozen_string_literal: true

module CDL
  class AutomaticIngester
    def self.run
      new(root_path: Figgy.config["cdl_in_path"]).run!
    end

    attr_reader :root_path
    def initialize(root_path:)
      @root_path = Pathname.new(root_path.to_s)
      FileUtils.mkdir_p(self.root_path.join("ingesting"))
    end

    def run!
      Dir.glob(root_path.join("*.pdf")).each do |file|
        file = Pathname.new(file)
        next unless RemoteRecord.catalog?(file.basename(".*").to_s)
        next unless Time.current - File.mtime(file.to_s) > 1.hour
        FileUtils.mv(file, root_path.join("ingesting", file.basename))
        CDL::PDFIngestJob.perform_later(file_name: file.basename.to_s)
      end
    end
  end
end
