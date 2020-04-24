# frozen_string_literal: true
require "csv"
class MissingMapImageService
  def self.move_images(csv_path:, in_dir:, out_dir:)
    new(csv_path: csv_path, in_dir: in_dir, out_dir: out_dir).move_images
  end

  def self.generate_tiffs(file_root:, in_dir:, out_dir:)
    new(csv_path: csv_path, in_dir: in_dir, out_dir: out_dir).generate_tiffs
  end

  attr_reader :csv_path, :in_dir, :out_dir
  def initialize(csv_path: nil, in_dir:, out_dir:)
    @csv_path = csv_path
    @in_dir = Pathname.new(in_dir)
    @out_dir = Pathname.new(out_dir)
  end

  def move_images
    counter = 0
    read_csv.each do |r|
      begin
        image_number = r["image_number"]
        counter += 1
        puts "#{counter} : #{image_number}"
        fn = filename(image_number)
        in_path = Dir.glob(in_dir.join("**/#{fn}")).first
        out_path = out_dir.join("#{image_number}.jp2")
        FileUtils.copy(in_path, out_path)
      rescue
        next
      end
    end
  end

  def generate_tiffs
    counter = 0
    Dir.glob(in_dir.join("**/*.jp2")).each do |path|
      counter += 1
      puts "#{counter} : #{path}"
      basename = File.basename(path, ".jp2")
      out_path = out_dir.join("#{basename}.tif")
      convert_jp2(path, out_path.to_s)
    end
  end

  private

    def convert_jp2(in_path, out_path)
      # temp_file = Tempfile.new(["tempfile", ".tif"])
      _stdout, stderr, status =
        Open3.capture3("opj_decompress", "-i", in_path, "-o", out_path)
      raise stderr unless status.success?
      out_path
    end

    def filename(image_number)
      leading_zeros = "0" * (8 - image_number.to_s.size)
      "#{leading_zeros}#{image_number}.jp2"
    end

    def read_csv
      CSV.read(csv_path, headers: true)
    end
end
