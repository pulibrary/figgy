# 15. Pulmap Indexing

Date: 2026-09-29

## Status

Accepted

## Context

We want to be able to handle arbitrarily large files, and not do more technical metadata gathering than we have use cases for.

## Decisions

We will remove the Tika characterization service as a general purpose fallback. Instead we will ensure that for all files we collect the checksum, mime_type, and file size.

If the mime_type matches another characterizer, then we'll run that, to ensure we get the data we need for each file type.

## Consequences

- If we decide we need more data than we have, we'd have to re-characterize every file. We've never needed this, or used the extra data from Tika.
- We'll lose bits_per_sample, x_resolution, y_resolution, camera_model, and software from our technical metadata. They'll still be stored in the file's data, which is preserved. We've never had a use case for that data, and were only gathering it in cases where for some reason a file uploaded couldn't identify its mime-type.
- Characterization should get much faster.
