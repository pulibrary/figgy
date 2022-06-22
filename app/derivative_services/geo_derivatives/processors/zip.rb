# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Zip
      extend ActiveSupport::Concern

      included do
        # Unzips a file, invokes a block, and then deletes the unzipped file(s).
        # Use to wrap processor methods for geo file formats that
        # are zipped before uploading.
        # @param in_path [String] file input path
        # @param output_file [String] processor output file path
        def self.unzip(in_path, output_file, _options = {})
          basename = File.basename(output_file, File.extname(output_file))
          zip_out_path = "#{File.dirname(output_file)}/#{basename}_out"
          execute "unzip -qq -j -d \"#{zip_out_path}\" \"#{in_path}\""
          yield zip_out_path
          FileUtils.rm_rf(zip_out_path)
        end

        # Zips a file or directory.
        # @param in_path [String] file input path
        # @param output_file [String] output zip file
        def self.zip(in_path, output_file, _options = {})
          execute "zip -j -qq -r \"#{output_file}\" \"#{in_path}\""
        end
      end
    end
  end
end
