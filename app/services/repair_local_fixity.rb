# frozen_string_literal: true

# Replaces files with the preservation copy from Google Cloud.
class RepairLocalFixity
  def self.run(file_set)
    new(file_set: file_set).run
  end

  attr_reader :file_set
  def initialize(file_set:)
    @file_set = file_set
  end

  def run
    preservation_object = Wayfinder.for(file_set).preservation_object
    replace_file_from_preservation_object(preservation_object)
    LocalFixityJob.perform_later(file_set.id.to_s)
  end

  private

    def replace_file_from_preservation_object(preservation_object)
      preservation_object.binary_nodes.each do |node|
        cloud_id = node.file_identifiers.first
        file_metadata_id = node.preservation_copy_of_id
        original_fm = file_set.file_metadata.find { |fm| fm.id == file_metadata_id }
        path = original_fm.file_identifiers.first.to_s.gsub("disk://", "")
        cloud_file = storage_adapter.find_by(id: cloud_id)
        Tempfile.create do |tf|
          FileUtils.copy_stream(cloud_file.stream, tf)
          cloud_checksum = Digest::MD5.file(tf).hexdigest
          if cloud_checksum == original_fm.checksum.first.md5
            FileUtils.copy(tf, path)
          end
        end
      end
    end

    def storage_adapter
      Valkyrie::StorageAdapter.find(:versioned_google_cloud_storage)
    end
end
