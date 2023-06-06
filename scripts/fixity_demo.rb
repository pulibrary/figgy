# frozen_string_literal: true
# This script aids in demo'ing automatic repair of files that fail fixity
# checks. You can find the documentation in
# docs/technical/preservation/file_repair.md
csp = ChangeSetPersister.default
local_storage_adapter = Valkyrie::StorageAdapter.find(:disk_via_copy)
cloud_storage_adapter = Valkyrie::StorageAdapter.find(:versioned_google_cloud_storage)

bad_local_file_set = ChangeSet.for(ScannedResource.new)
bad_cloud_file_set = ChangeSet.for(ScannedResource.new)
both_bad = ChangeSet.for(ScannedResource.new)
file_path = Rails.root.join("spec", "fixtures", "files", "example.tif")

bad_local_file_set.validate(title: "Bad Local File Set", state: "complete", files: [IngestableFile.new(file_path: file_path, original_filename: "file.tif", mime_type: "image/tiff")])
bad_cloud_file_set.validate(title: "Bad Cloud File Set", state: "complete", files: [IngestableFile.new(file_path: file_path, original_filename: "file.tif", mime_type: "image/tiff")])
both_bad.validate(title: "Bad Local & Cloud File Set", state: "complete", files: [IngestableFile.new(file_path: file_path, original_filename: "file.tif", mime_type: "image/tiff")])

bad_local_file_set = csp.save(change_set: bad_local_file_set)
bad_cloud_file_set = csp.save(change_set: bad_cloud_file_set)
both_bad = csp.save(change_set: both_bad)

puts "Push any key after files are preserved to corrupt files."

gets

# Corrupt local file
[bad_local_file_set, both_bad].each do |resource|
  fs = Wayfinder.for(resource).file_sets.first
  local_storage_adapter.upload(file: File.open(Rails.root.join("spec", "fixtures", "files", "invalid.tif")), original_filename: fs.original_file.label.first, resource: fs.original_file)
end

# Corrupt Cloud Files
[bad_cloud_file_set, both_bad].each do |resource|
  fs = Wayfinder.for(resource).file_sets.first
  po = Wayfinder.for(fs).preservation_object
  cloud_storage_adapter.upload(file: File.open(Rails.root.join("spec", "fixtures", "files", "invalid.tif")), original_filename: po.binary_nodes.first.label.first, resource: fs)
end

puts "BAD LOCAL FILE SET"
fileset_id = bad_local_file_set.member_ids.first
puts "Push any key to execute cloud fixity check of #{bad_local_file_set.id}"
gets

CloudFixity::FixityRequestor.queue_resource_check!(id: fileset_id)
puts "Push any key to execute local fixity check and repair of #{bad_local_file_set.id}"
gets

LocalFixityJob.perform_now(fileset_id)

puts "BAD CLOUD FILE SET"
fileset_id = bad_cloud_file_set.member_ids.first
puts "Push any key to execute local fixity check of #{bad_cloud_file_set}"
gets

LocalFixityJob.perform_now(fileset_id)
puts "Push any key to execute cloud fixity check and repair of #{bad_cloud_file_set}"
gets

CloudFixity::FixityRequestor.queue_resource_check!(id: fileset_id)

puts "Both Bad"
fileset_id = both_bad.member_ids.first
puts "Push any key to execute fixity checks for both bad - it will report being broken."
gets
LocalFixityJob.perform_now(fileset_id)

CloudFixity::FixityRequestor.queue_resource_check!(id: fileset_id)
