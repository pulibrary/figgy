# How to Demo File Repair

## Create resources
In the figgy staging instance, create 3 scanned resources which each have one image. Name them clearly so you can tell which is which, e.g.
  * Test Repair Bad Cloud File
  * Test Repair Bad Local File
  * Test Repair Bad Cloud and Local Files

Complete each resource so they all preserve to the cloud.

## Corrupt a local file
You'll want to corrupt the local file for both the "bad local file" and the "bad
cloud and local files" objects.

`$ bundle exec cap staging rails:console`

```ruby
# set an id variable to your fileset's id
qs = ChangeSetPersister.default.query_service
fs = qs.find_by(id: id)
fs.file_metadata.first.file_identifiers.first
```

This will print the disk location of the local file. ssh to the staging box and
cd to that location. then you can corrupt it by appending something to the end
of it, e.g.
```
% echo "p0wn3d" >> [filename].tif
```

## Corrupt a cloud file
You'll want to corrupt the cloud file for both the "bad cloud file" and the "bad
cloud and local files" objects.

`$ bundle exec cap staging rails:console`

```
# set an id variable to your fileset's id
qs = ChangeSetPersister.default.query_service
fs = qs.find_by(id: id)
po = Wayfinder.for(fs).preservation_object
po.binary_nodes.first.file_identifiers.first.id
```

* go to console.cloud.google.com
* make sure you're logged in with your princeton account (check your avatar on the top right)
* select pulibrary-figgy-storage from the project drop-down
* search for and/or navigate to cloud storage
* select figgy-staging-preservation 
* filter to the first part of the id to get into the right folder, then keep
    clicking through the paths until you see the file listed.
* Upload some other file (you can use `spec/fixtures/files/bad.tif`)
* copy the filename of the good file, then delete it
* rename the bad file to have the good file's name

## Force the repair

For 'Test Repair Bad Local File'

An object where we've corrupted the local isilon file
1. Run cloud fixity check on the FileSet with `CloudFixity::FixityRequestor.queue_resource_check!(id: fileset_id)`. The fileset's cloud fixity timestamp should update.
1. Run local fixity check on the FileSet with `LocalFixityJob.perform_now(fileset_id)`. We saw it enqueue and perform the RepairLocalFixityJob. You can downloaded the cloud file before and after. The file status should change to healthy.

For 'Test Repair Bad Cloud File'

1. Run local fixity check. Should succeed.
1. Run cloud fixity check. Should repair.


For 'Test Repair Bad Cloud and Local Files'

1. Run cloud fixity check (which kicks off a local fixity check as well). Both should fail and resource should report a broken state.
