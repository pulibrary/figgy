# 7. JPEG2000 Ingest

Date: 2020-04-24

## Status

Accepted

## Context

Support for ingestion of JPEG2000 images was added to accommodate
scanned map records for which we cannot find original TIFFs. The VIPS library,
used to generate pyramidal tiffs and thumbnails, can't read JP2s
directly, so a temporary intermediate TIFF was generated using the OpenJPEG `opj_decompress`
command. This command uses a large amount of memory and will eventually
crash the host server if several JP2s are decompressed simultaneously.

## Decisions

1. Derivative generation functionality for JPEG2000 images was removed.

## Consequences

1. Figgy can no longer generate derivaties for ingested JPEG2000 images.
1. If this functionality is needed in the future, a better performing
   intermediate step is required.
