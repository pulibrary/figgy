# Note to use these in your test you'll need to set with_queue_adapter :inline
def create_preserved_resource
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  file = fixture_file_upload("files/example.tif", "image/tiff")
  resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  change_set_persister.save(change_set: change_set)
end

def create_resource_unpreserved_metadata
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  resource = FactoryBot.create_for_repository(:complete_scanned_resource)
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  resource = change_set_persister.save(change_set: change_set)
  po = Wayfinder.for(resource).preservation_objects.first
  po.metadata_node = nil
  change_set_persister.save(change_set: ChangeSet.for(po))
  resource
end

def create_file_set_bad_binary_checksum
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  file = fixture_file_upload("files/example.tif", "image/tiff")
  resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  resource = change_set_persister.save(change_set: change_set)
  file_set = Wayfinder.for(resource).file_sets.first
  po = Wayfinder.for(file_set).preservation_objects.first
  modify_file(po.binary_nodes.first.file_identifiers.first)
  file_set
end

def create_resource_bad_metadata_checksum
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  resource = FactoryBot.create_for_repository(:complete_scanned_resource)
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  resource = change_set_persister.save(change_set: change_set)
  po = Wayfinder.for(resource).preservation_objects.first
  modify_file(po.metadata_node.file_identifiers.first)
  resource
end

def create_resource_bad_metadata_lock_token
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  resource = FactoryBot.create_for_repository(:complete_scanned_resource)
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  resource = change_set_persister.save(change_set: change_set)
  po = Wayfinder.for(resource).preservation_objects.first
  po.metadata_version = "6"
  ChangeSetPersister.default.metadata_adapter.persister.save(resource: po)
  resource
end

def create_resource_no_metadata_file
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  resource = FactoryBot.create_for_repository(:complete_scanned_resource)
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  resource = change_set_persister.save(change_set: change_set)
  po = Wayfinder.for(resource).preservation_objects.first
  path = po.metadata_node.file_identifiers.first.to_s.gsub("disk://", "")
  FileUtils.rm(path)
  resource
end

def create_file_set_no_binary_file
  change_set_persister = ChangeSetPersister.default
  query_service = change_set_persister.query_service

  file = fixture_file_upload("files/example.tif", "image/tiff")
  resource = FactoryBot.create_for_repository(:complete_scanned_resource, files: [file])
  reloaded_resource = query_service.find_by(id: resource.id)
  change_set = ChangeSet.for(reloaded_resource)
  resource = change_set_persister.save(change_set: change_set)
  file_set = Wayfinder.for(resource).file_sets.first
  po = Wayfinder.for(file_set).preservation_objects.first
  path = po.binary_nodes.first.file_identifiers.first.to_s.gsub("disk://", "")
  FileUtils.rm(path)
  file_set
end

def create_recording_unpreserved_binary
  recording = FactoryBot.create_for_repository(:complete_recording_with_real_files)
  recording_file_set = Wayfinder.for(recording).file_sets.first
  intermediate_file = recording_file_set.intermediate_file
  fs_po = Wayfinder.for(recording_file_set).preservation_objects.first
  fs_po.binary_nodes = fs_po.binary_nodes.find { |node| node.preservation_copy_of_id != intermediate_file.id }
  ChangeSetPersister.default.save(change_set: ChangeSet.for(fs_po))
  recording_file_set
end
