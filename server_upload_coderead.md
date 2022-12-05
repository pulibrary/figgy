# Server upload code read

## Bulk ingest

From a bulk ingest form you can create one or more resources and have their
files added according to a predetermined directory structure.

bulk_ingest_controller loads `bulk_ingest/show.html.erb` which includes
`browse_everything/_modal.html.erb`, which loads the browse everything react app.

BE loads the file picker. the form gets submitted to the browse_everything_files
action. the files are passed as a param browse_everything_params["uploads"] holding an array of UUIDs. those IDs are used to fetch [BrowseEverything::Upload](https://github.com/samvera/browse-everything/blob/04916c6769ef7ee1572954fe7b7d0107d8625506/lib/browse_everything/upload.rb) objects. Then it calls BrowseEverythingLocalIngester.ingest.

prefer passing an array of strings reflecting relative or absolute file locations.
pass as ingest_paths[].

The BrowseEverythingLocalIngester gets the containers of the Upload objects and
gets ingest paths from there. passes on to IngestFolderJob. It calls
BulkIngestService.attach_dir

## File picker ingest

From the file manager page you can ingest one or more files onto an existing
resource.

The file manager is defined in the ResourcesController and the view is in
`base/file_manager.html.erb`. there are several partials. Eventually the browse
everything modal is rendered from `_base/_server_upload.html.erb`.
Then it posts the result to the resources_controller browse_everything_files action.

The action uses the browse_everything_params["uploads"] array of ids to create
PendingUpload objects which hold the id from that array.  these get passed into 
change set with both the `pending_uplaods` key and the `files` key. https://github.com/pulibrary/figgy/blob/5df2a90dbc7c3e3e81755337eac24e960b1b151e/app/controllers/resources_controller.rb#L167

question: in the above line of code, when would the change set already have some
pending uploads? Maybe this happens when some uploads have been enqueued but not
run yet? I'm not sure I understand what pending uploads is all about.

Anyway this then gets added via the file appender.

## Save and Ingest

If your directory is named correctly figgy can auto-discover the files to add to
the resource it creates.

This 


