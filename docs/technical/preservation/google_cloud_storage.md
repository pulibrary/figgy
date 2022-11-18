# Google Cloud Storage

## Creating a Google Cloud Project
Please see the documentation for this at https://cloud.google.com/resource-manager/docs/creating-managing-projects

## Creating Service Credentials
The service documentation also provides an outline of this process at https://cloud.google.com/docs/authentication/production#obtaining_and_providing_service_account_credentials_manually

*Note that the service user for the Project must have the "Storage Object Admin" privileges, please see [descriptions outlining Identity and Access Management](https://cloud.google.com/iam/docs/understanding-roles#storage-roles) further information.*

## Configuration
Within `config/config.yml`, provide the Google Cloud Storage Bucket ID for the `preservation_bucket` (by default this is set to `figgy-development-preservation`).

In order to deploy the application (e. g. invoking `bundle exec rails server` or `bundle exec foreman start`, set the environment variable `STORAGE_PROJECT` to the ID for the Google Cloud Project, and set `STORAGE_CREDENTIALS` to the path for the Google Cloud Project service credentials.
