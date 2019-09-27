# frozen_string_literal: true
require "digest"
require "zip"
require "tmpdir"
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
      Zip::File.open(File.join(base_path, package.id.to_s + ".zip"),
                     Zip::File::CREATE) do |zipfile|
        deposit_files(zipfile)
        deposit_metadata(zipfile)
        deposit_checksums(zipfile)
      end
    end

    private

      def deposit_files(zipfile)
        package.pages.each do |page|
          digester.reset
          zipfile.add(page.name + ".tif", page.tiff_path)
          digester.file page.tiff_path
          checksums[page.name + ".tif"] = digester.hexdigest

          if page.ocr?
            digester.reset
            zipfile.get_output_stream(page.name + ".txt") { |f| f.write page.to_txt }
            digester << page.to_txt
            checksums[page.name + ".txt"] = digester.hexdigest
          end

          next unless page.hocr?
          digester.reset
          zipfile.get_output_stream(page.name + ".html") { |f| f.write page.to_html }
          digester << page.to_html
          checksums[page.name + ".html"] = digester.hexdigest
        end
      end

      def deposit_checksums(zipfile)
        zipfile.get_output_stream("checksum.md5") do |f|
          # iterate over k,v in checksums
          checksums.each { |k, v| f.write format("%s %s\n", v, k) }
        end
      end

      def deposit_metadata(zipfile)
        digester.reset
        digester << package.metadata
        zipfile.get_output_stream("meta.yml") { |f| f.write package.metadata }
        checksums["meta.yml"] = digester.hexdigest
      end
  end
end
