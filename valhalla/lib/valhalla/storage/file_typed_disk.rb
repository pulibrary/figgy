# frozen_string_literal: true
module Valhalla::Storage
  class FileTypedDisk < Valkyrie::Storage::Disk
    def initialize(master_storage_adapter:, derivative_storage_adapter:)
      @master_storage_adapter = master_storage_adapter
      @derivative_storage_adapter = derivative_storage_adapter
    end

    def upload(file:, resource: nil)
      file_typed_adapter(file: file).upload(file: file, resource: resource)
    end

    private

      def file_typed_adapter(file:)
        file.derivative? ? @derivative_storage_adapter : @master_storage_adapter
      end
  end
end
