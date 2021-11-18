# Preservation Documentation

## Pub/Sub Configuration

1. Production
  ```
  gcloud beta pubsub topics create figgy-production-fixity-request
  echo '{"bindings":[{"members":["serviceAccount:figgy-preservation-production@pulibrary-figgy-storage-1.iam.gserviceaccount.com"],"role":"roles/pubsub.editor"}],"etag":"ACAB"}' > permissions.json
  gcloud beta pubsub topics set-iam-policy projects/pulibrary-figgy-storage-1/topics/figgy-production-fixity-request permissions.json
  rm permissions.json
  gcloud beta pubsub topics create figgy-production-fixity-status
  echo '{"bindings":[{"members":["serviceAccount:figgy-preservation-production@pulibrary-figgy-storage-1.iam.gserviceaccount.com"],"role":"roles/pubsub.editor"}],"etag":"ACAB"}' > permissions.json
  gcloud beta pubsub topics set-iam-policy projects/pulibrary-figgy-storage-1/topics/figgy-production-fixity-status permissions.json
  gcloud beta pubsub subscriptions create figgy-production-fixity-status --topic figgy-production-fixity-status --expiration-period=never
  gcloud beta pubsub subscriptions set-iam-policy projects/pulibrary-figgy-storage-1/subscriptions/figgy-production-fixity-status permissions.json
  rm permissions.json
  ```

2. Staging
  ```
  gcloud beta pubsub topics create figgy-staging-fixity-request
  echo '{"bindings":[{"members":["serviceAccount:figgy-staging@pulibrary-figgy-storage-1.iam.gserviceaccount.com"],"role":"roles/pubsub.editor"}],"etag":"ACAB"}' > permissions.json
  gcloud beta pubsub topics set-iam-policy projects/pulibrary-figgy-storage-1/topics/figgy-staging-fixity-request permissions.json
  rm permissions.json
  gcloud beta pubsub topics create figgy-staging-fixity-status
  echo '{"bindings":[{"members":["serviceAccount:figgy-staging@pulibrary-figgy-storage-1.iam.gserviceaccount.com"],"role":"roles/pubsub.editor"}],"etag":"ACAB"}' > permissions.json
  gcloud beta pubsub topics set-iam-policy projects/pulibrary-figgy-storage-1/topics/figgy-staging-fixity-status permissions.json
  gcloud beta pubsub subscriptions create figgy-staging-fixity-status --topic figgy-staging-fixity-status --expiration-period=never
  gcloud beta pubsub subscriptions set-iam-policy projects/pulibrary-figgy-storage-1/subscriptions/figgy-staging-fixity-status permissions.json
  rm permissions.json
  ```
