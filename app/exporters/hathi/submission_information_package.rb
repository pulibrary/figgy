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
      :mode => 0700)
      deposit_files()
      deposit_metadata()
      deposit_checksums()
    end
    
    private
    
    def deposit_files
      package.pages.each do |page|
        digester.reset
        FileUtils.cp page.tiff_path, 
          File.join(@export_dir, page.name + ".tif")
        digester.file page.tiff_path
        checksums[page.name + ".tif"] = digester.hexdigest
        
        if page.ocr?
          digester.reset
          File.open(File.join(@export_dir, page.name + ".txt"), "w")  do |f|
            f.write page.to_txt
          end
          digester << page.to_txt
          checksums[page.name + ".txt"] = digester.hexdigest
          
          next unless page.hocr?

          digester.reset
          File.open(File.join(@export_dir, page.name + ".html"), "w") do |f|
            f.write page.to_html
          end
          digester << page.to_html
          checksums[page.name + ".html"] = digester.hexdigest
        end
      end
    end
    
    def deposit_checksums()
      File.open(File.join(@export_dir, "checksum.md5"), "w") do |f|
        # iterate over k,v in checksums
        checksums.each { |k, v| f.write format("%s %s\n", v, k) }
      end
    end
    
    def deposit_metadata()
      digester.reset
      digester << package.metadata
      File.open(File.join(@export_dir, "meta.yml"), "w") do |f|
        f.write package.metadata
      end
      checksums["meta.yml"] = digester.hexdigest
    end
  end
end
