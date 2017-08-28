# frozen_string_literal: true
class MigrationAdapter < Valkyrie::Storage::Disk
  attr_reader :file_mover
  def initialize(base_path:, file_mover: FileUtils.method(:mv))
    super(base_path: base_path)
    @file_mover = file_mover
  end

  # @param file [IO]
  # @param resource [Valkyrie::Resource]
  # @return [Valkyrie::StorageAdapter::File]
  def upload(file:, resource: nil)
    new_path = base_path.join(resource.try(:id).to_s, file.original_filename)
    FileUtils.mkdir_p(new_path.parent)
    file_mover.call(file.path, new_path)
    find_by(id: Valkyrie::ID.new("disk://#{new_path}"))
  end
end
