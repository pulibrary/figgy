# frozen_string_literal: true

require "digest"
require "tmpdir"
require "fileutils"

module Hathi
  class SubmissionInformationPackage
    # See https://www.hathitrust.org/deposit_guidelines
    attr_reader :package, :base_path, :digester, :checksums
    def initialize(package:, base_path:)
      @package = package
      @base_path = base_path
      @checksums = {}
      @digester = Digest::MD5.new
    end

    def export
      @export_dir = FileUtils.mkdir(
        File.join(base_path, package.id.to_s + "_sip"),
        mode: 0o700
      )
      deposit_files
      deposit_metadata
      deposit_checksums
    end

    private

      def deposit_files
        package.pages.each do |page|
          digester.reset
          FileUtils.cp page.path_to_file,
            File.join(@export_dir, page.image_filename)
          digester.file page.path_to_file
          checksums[page.image_filename] = digester.hexdigest

          next unless page.ocr?
          digester.reset
          File.write(File.join(@export_dir, page.ocr_filename), page.to_txt)
          digester << page.to_txt
          checksums[page.ocr_filename] = digester.hexdigest

          next unless page.hocr?

          digester.reset
          File.write(File.join(@export_dir, page.hocr_filename), page.to_html)
          digester << page.to_html
          checksums[page.hocr_filename] = digester.hexdigest
        end
      end

      def deposit_checksums
        File.open(File.join(@export_dir, "checksum.md5"), "w") do |f|
          # iterate over k,v in checksums; two spaces so md5sum command can verify
          checksums.each { |k, v| f.write format("%s  %s\n", v, k) }
        end
      end

      def deposit_metadata
        digester.reset
        digester << package.metadata.to_yaml
        File.write(File.join(@export_dir, "meta.yml"), package.metadata.to_yaml)
        checksums["meta.yml"] = digester.hexdigest
      end
  end
end
