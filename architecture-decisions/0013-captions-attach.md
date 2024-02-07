# 12. Attaching Captions to Videos (Modeling)

Date: 2024-02-05

## Status

Accepted

## Context

Our use cases for Video can be found in our [use case documentation](/docs/ux/use_cases.md#videos).

They point to videos in Figgy needing a 1-N relationship with closed caption files. We discussed a few options:

1. FileSets have an extra FileMetadata users can upload which contains the captions, the label of the caption, and the language the caption is for.
2. FileSets have a descriptive property that contains many nested `Caption` models.
3. Resources can have a FileSet which is the caption, and that FileSet will have a `transcript_for_id` property to point to the video it's a transcript for.

We compared these options against ease of implementation, ease of reasoning, flexibility for anticipated use cases, and potential performance. We decided ease of reasoning was the most important of those.

## Decisions

FileSets will have an extra FileMetadata users can upload which contains the captions, the label of the caption, and the language the caption is for. This model matches our existing mental model of the way a FileSet contains an original file and all of its supporting files.

## Consequences

1. We have to develop functionality to upload and delete user-defined FileMetadata.
1. If a user deletes a FileSet they will have to upload two files (the original file and the caption) to re-create it.
