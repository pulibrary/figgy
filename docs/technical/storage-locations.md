# Storage Locations

Figgy stores and retrieves binary content and metadata from a variety of locations.

## Primary Locations

### Original Binary Content

Binary content (images, audio files, zips, etc - the things uploaded) are stored on the Isilon and mapped to Figgy at `/opt/repository/files`, which goes to `/mnt/diglibdata/hydra_binaries/figgy_production` in production.

### Metadata

Metadata is stored in Figgy in PostgreSQL. Figgy has its own PostgreSQL cluster (one primary and one warm backup.)

### Search Index

We index into our Solr cluster.

### Derivatives

#### Images

Pyramidal tiffs are saved in AWS for our lambda-based IIIF tile server in the [iiif-image-production](https://s3.console.aws.amazon.com/s3/buckets/iiif-image-production?region=us-east-1&bucketType=general&tab=objects) bucket.

#### AV HLS Files

HLS derivatives are stored on the Isilon, mounted at `/opt/repository/stream_derivatives` which goes to `/mnt/diglibdata/hydra_binaries/figgy_stream_derivatives`.

#### GIS Derivatives

GIS derivatives are stored in AWS in the [figgy-geo-production](https://s3.console.aws.amazon.com/s3/buckets/figgy-geo-production?region=us-east-1&bucketType=general&tab=objects) bucket.

## Backups

### Binary Content

Figgy's Isilon data is synced to AWS via AWS DataSync at a regular interval to an [AWS bucket](https://s3.console.aws.amazon.com/s3/buckets/diglibdata2-hydra?region=us-east-2&bucketType=general&prefix=hydra-binaries-figgy_production/&showversions=false)

### Solr

Solr is backed up daily and synced to GCS in the [pul-solr-backup](https://console.cloud.google.com/storage/browser/pul-solr-backup/daily/solr8/production) bucket.

### PostgreSQL (Metadata)

#### Warm Standby

Figgy's production and staging databases have a warm standby. If the primary fails, you can promote the standby by deleting the `standby.signal` file in the standby's `/var/lib/postgresql/15/main` directory, restarting postgresql (`sudo service postgresql restart`), and pointing the Figgy servers at the now primary database.

#### Nightly Backup

Every day a Figgy snapshot is taken via `pg_dump` and uploaded to a GCS bucket using `restic`. Information on access and usage can be found in the [PUL IT Handbook](https://github.com/pulibrary/pul-it-handbook/blob/main/services/postgresql.md).

## Preservation

We store preservation copies of every object in a structure that preserves a resource's metadata, hierarchy, and non-derivative content in GCS. You can find all the files in the [figgy-preservation](https://console.cloud.google.com/storage/browser/figgy-preservation;tab=objects?forceOnBucketsSortingFiltering=true&authuser=1&project=pulibrary-figgy-storage-1&prefix=&forceOnObjectsSortingFiltering=false) bucket. It's expected that these are restored through Figgy.
