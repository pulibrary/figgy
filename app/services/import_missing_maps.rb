# frozen_string_literal: true
require "csv"
class ImportMissingMaps
  def self.import_map_set(csv_path:, parent_id:, file_root:, depositor:)
    new(csv_path: csv_path, file_root: file_root, depositor: depositor).import_mapset_from_csv(parent_id: parent_id)
  end

  def self.import_maps(csv_path:,file_root:, depositor:)
    new(csv_path: csv_path, file_root: file_root, depositor: depositor).import_maps
  end

  attr_reader :depositor, :csv_path, :parent_id, :file_root
  def initialize(csv_path:, parent_id: nil, file_root:, depositor:)
    @depositor = depositor
    @csv_path = csv_path
    @parent_id = parent_id
    @file_root = Pathname.new(file_root)
  end

  def import_mapset_from_csv(parent_id:)
    parent_resource = find(parent_id)
    import_map_set(map_records: read_csv, parent_resource: parent_resource)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    puts "Resource not found: #{parent_id}"
  end

  def import_maps
    records = read_csv
    create_new_maps(records)
  end

  private

    def import_map_set(map_records:, parent_resource:)
      child_map_ids = create_new_maps(map_records).map(&:id)
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        change_set = DynamicChangeSet.new(parent_resource)
        change_set.member_ids = child_map_ids + change_set.member_ids
        buffered_change_set_persister.save(change_set: change_set)
      end
    end

    def create_new_maps(maps)
      resources = []
      maps.each do |map|
        next unless map_file_exists(image_number: map["image"])
        new_resource = ScannedMap.new
        new_resource_change_set = ScannedMapChangeSet.new(new_resource)
        new_resource_change_set.validate(**scanned_map_attributes(map))
        persisted_map = change_set_persister.save(change_set: new_resource_change_set)
        resources << persisted_map
      end
      resources
    end

    def scanned_map_attributes(map)
      {
        identifier: map["ark"],
        visibility: map["visibility"],
        portion_note: map["label"],
        source_metadata_identifier: map["bibid"],
        local_identifier: map["image"],
        files: [map_file(image_number: map["image"], label: map["label"])],
        depositor: depositor
      }
    end

    # def filename(image_number)
    #   leading_zeros = "0" * (8 - image_number.to_s.size)
    #   "#{leading_zeros}#{image_number}.jp2"
    # end
    #

    def map_file_exists(image_number:)
      file_path = Dir.glob(file_root.join("**/#{image_number}.tif")).first
      return false unless file_path
      File.exist? file_path
    end

    def map_file(image_number:, label:)
      file_path = Dir.glob(file_root.join("**/#{image_number}.tif")).first
      return [] unless file_path
      return [] unless File.exist? file_path
      IngestableFile.new(
        file_path: file_path,
        mime_type: "image/tiff",
        original_filename: File.basename(file_path),
        copyable: false,
        container_attributes: {
          title: File.basename(file_path)
        }
      )
    end

    def read_csv
      CSV.read(csv_path, headers: true)
    end

    def change_set_persister
      @change_set_persister ||= ScannedMapsController.change_set_persister
    end

    def storage_adapter
      Valkyrie.config.storage_adapter
    end

    def adapter
      Valkyrie.config.metadata_adapter
    end

    def query_service
      adapter.query_service
    end

    def find(id)
      query_service.find_by(id: Valkyrie::ID.new(id))
    end
end
