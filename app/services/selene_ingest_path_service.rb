# frozen_string_literal: true
class SeleneIngestPathService
  attr_reader :path
  # @param path [Pathname] Full path to the selene directory
  def initialize(path)
    @path = path
  end

  def validate
    selene_structure.none?(&:nil?)
  end

  # Extract meters per pixel from depthmap tfw file
  def meters_per_pixel
    File.open(depthmap_tfw, &:gets)
  end

  private

    def selene_structure
      [
        depthmap_tfw,
        path.children.find { |c| c.basename.to_s.match(/1\.(tif|TIF)/) },
        path.children.find { |c| c.basename.to_s.match(/2\.(tif|TIF)/) },
        path.children.find { |c| c.basename.to_s.match(/3\.(tif|TIF)/) },
        path.children.find { |c| c.basename.to_s.match(/4\.(tif|TIF)/) }
      ]
    end

    def depthmap_tfw
      output_dir = path.children.find { |c| c.basename.to_s == "Selene_Output" }
      return nil unless output_dir
      output_dir.children.find { |c| c.basename.to_s == "depthmap_m1.tfw" }
    end
end
