# 12. Attaching Captions to Videos (Modeling)

Date: 2024-02-05

## Status

Accepted

## Context

We have the following use cases for video:

As Princeton University I should only allow the public to view videos that have subtitles which can render in the viewer both to legally protect ourselves and more importantly to meet our goals of accessibility. We want (.VTT) files for transcription subtitles so that we can standardize and migrate if need be.

As a Figgy staff member I should be able to bulk ingest several videos, each with their own resource along with their captions so that I can have a vendor mass digitize materials and then ingest them later.

As a Figgy staff member I should be able to ingest several videos to one resource, each with their own captions, and the viewer should render them with a table of contents so that I can display multiple videos in a single "box" of content in the archives.

As Princeton University I want to preserve the captions along with the video so that if Figgy's data is ever lost I can restore them.

As a researcher I want to have multiple captions each in their own language and users should be able to switch between them so that I can provide translations in addition to transcription.

As such, videos in Figgy need a 1-N relationship with closed caption files. We discussed a few options:

1. FileSets have an extra FileMetadata users can upload which contains the captions, the label of the caption, and the language the caption is for.
2. FileSets have a descriptive property that contains many nested `Caption` models.
3. Resources can have a FileSet which is the caption, and that FileSet will have a `transcript_for_id` property to point to the video it's a transcript for.

We compared these options against ease of implementation, ease of reasoning, flexibility for anticipated use cases, and potential performance. We decided ease of reasoning was the most important of those.

## Decisions

FileSets will have an extra FileMetadata users can upload which contains the captions, the label of the caption, and the language the caption is for. This model matches our existing mental model of the way a FileSet contains an original file and all of its supporting files.

## Consequences

1. We have to develop functionality to upload and delete user-defined FileMetadata.
1. Users will have to upload two files (the original file and the caption) if they delete a FileSet to re-upload it.
