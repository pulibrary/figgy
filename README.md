# Figgy

A digital repository application in use at Princeton University Library for storing and managing digital representations of manuscripts, ephemera, vector, and raster data for export into a variety of front-end displays.

[![CircleCI](https://circleci.com/gh/pulibrary/figgy.svg?style=svg)](https://circleci.com/gh/pulibrary/figgy)
[![Browserstack](./browserstack-logo.svg)](https://www.browserstack.com/)

## Language Dependencies

For asdf users `./bin/setup` will ensure that required languages are installed at the right versions. (See note on java, below)

Otherwise consult `.tool-versions` for required languages and their current versions.

### Java via ASDF on Mac
You need to add the following line to your `~/.asdfrc` file:

```
java_macos_integration_enable = yes
```

And if you have this line you may need to remove it:

```
legacy_version_file = yes
```

After making these changes open a new terminal window for figgy.

## Package Dependencies

The following dependencies will be installed via homebrew by `./bin/setup`:

* [ImageMagick](https://www.imagemagick.org)
* [GDAL](http://www.gdal.org/)
* [Tesseract](https://github.com/tesseract-ocr/tesseract)
    * Note that version 3.04 is on the servers but homebrew installs 4.1.1
* [MediaInfo](https://mediaarea.net/en/MediaInfo)
* [FFMpeg](http://www.ffmpeg.org/) (for AV derivatives)
* [VIPS]
* [OCRmyPDF](https://ocrmypdf.readthedocs.io/)
* [cogeo-mosaic](https://github.com/developmentseed/cogeo-mosaic) for mosaic manifest generation

Other dependencies:

* [Google Chrome](https://google.com/chrome/) (for feature tests)
* Postgres (for OSX dev systems, install via homebrew)
* [Redis](http://redis.io/)
    * Start Redis with `redis-server` or if you're on certain Linuxes, you can do this via `sudo service redis-server start`.
* [RabbitMQ](https://www.rabbitmq.com/) (Optional)
    * Start with rabbitmq-server
    * Used for publishing create/update/delete events for systems such as
      [Pomegranate](https://github.com/pulibrary/pomegranate)

## Automatically pull vault password from lastpass

These steps are performed by `./bin/setup`.

More information about lastpass-cli can be found here: https://lastpass.github.io/lastpass-cli/lpass.1.html
```
brew install lastpass-cli
lpass login <email@email.com>
```

## Initial Setup

```sh
git clone https://github.com/pulibrary/figgy.git
cd figgy
./bin/setup
bundle install
yarn install
```

Remember you'll need to run `bundle install` and `yarn install` on an ongoing basis as dependencies are updated.

## Setup server

You can either run Solr/Postgres locally or spin them up in Docker containers
with Lando.

### Lando

Lando will automatically set up docker images for Solr and Postgres which match
the versions we use in Production. The ports will not collide with any other
projects you're using Solr/Postgres for, and you can easily clean up with `lando
destroy` or turn off all services with `lando poweroff`.

1. Install Lando DMG from [[https://github.com/lando/lando/releases]]
1. `bundle exec rake servers:start`

1. For test:
   - In a separate terminal: `bundle exec rspec`
   - Run jest tests: `yarn test`
1. For development:
   - In a separate terminal: `bundle exec foreman start`
     - Or run services separately as shown in [[https://github.com/pulibrary/figgy/blob/master/Procfile]]
   - Access Figgy at http://localhost:3000/

## Load sample development data

1. Log in to your development instance using your princeton credentials; this creates your user in figgy's db. If you only have user access and need admin access, run `bundle exec rake figgy:set_admin_user`
1. Start sidekiq (see below)
1. `rails db:seed` # pipe through `grep -v WARN` to ignore log warnings about the rabbitmq port

## Background workers

Some tasks are performed by background workers. To run a Sidekiq background worker process to execute
background jobs that are queued:

```
bundle exec sidekiq
```

## Loading controlled vocabularies

To load the controlled vocabularies in `config/vocab/`:
  - `rake figgy:vocab:load CSV=config/vocab/iso639-1.csv NAME="LAE Languages"`
  - `rake figgy:vocab:load CSV=config/vocab/iso639-2.csv NAME="ISO-639-2 Languages"`
  - `rake figgy:vocab:load CSV=config/vocab/lae_areas.csv NAME="LAE Areas"`
  - `rake figgy:vocab:load CSV=config/vocab/lae_genres.csv NAME="LAE Genres" LABEL=pul_label`
  - `rake figgy:vocab:load CSV=config/vocab/lae_subjects.csv NAME="LAE Subjects" CATEGORY=category`

## Uploading files

By default, Figgy provides users with the ability to upload binaries from the local file system environment using the directory [https://github.com/pulibrary/figgy/tree/master/staged_files](/staged_files).  One may copy files into this directory for aiding in development, and may upload these files in this directory using the "File Manager" interface (exposed after saving a Work).

### Google Drive Storage Support

Figgy may also be configured to upload files from hosted storage providers.  Support for users with Google Drive accounts has been tested and verified.  [Please reference the Browse Everything documentation for more details](https://github.com/pulibrary/figgy/blob/master/BROWSE_EVERYTHING.md).

## Preservation Configuration in Development

Figgy uses Google Cloud Storage buckets for providing support for preserving certain resources.  Please find further documentation outlining the configuration for Google Cloud service authentication and permissions management [here](https://github.com/pulibrary/figgy/blob/master/GOOGLE_CLOUD_STORAGE.md).

By default, in development, preserved objects will be stored in the directory
"tmp/cloud_backup." If you'd like to configure and test Google Cloud storage
instead, do the following:

1. Download and save gcs_pulibrary-staging-credentials.json from LastPass into
   the `tmp` directory.
2. Create a `.env` file in the root with the following settings:
   ```
   STORAGE_PROJECT=pulibrary-figgy-storage-1
   STORAGE_CREDENTIALS=tmp/gcs_pulibrary-staging-credentials.json
   ```
3. Restart the server. Now items marked with the `cloud` preservation policy
   will save to a bucket you can view at `https://console.cloud.google.com/storage/browser`
4. Items only last in this bucket for 2 days, and aren't versioned.

## Administering Figgy
To put figgy in readonly mode, use the [ansible playbook](https://github.com/pulibrary/princeton_ansible/blob/master/playbooks/figgy_toggle_readonly.yml). Be mindful of the value of the `figgy_read_only_mode` variable when provisioning during readonly downtime. It defaults to false and could therefore turn off readonly mode prematurely if you don't override it.

## Cloud Fixity Checking

Documentation on setup for staging/production Fixity configuration can be found
in [preservation_documentation.md](/preservation_documentation.md).

### Deployment Steps

1. `gcloud components install beta`
1. `gcloud auth login`
1. `gcloud config set project pulibrary-figgy-storage-1`
1. `cap [staging/production] deploy:google_cloud_function`

## ArchivesSpace Synchronization

Figgy will persist DAOs to ArchivesSpace on completion of finding aid resources.
To set this up in development, do the following:

1. `lpass login <email>`
1. `bundle exec rake figgy:setup_keys`

## Read-only Maintenance Windows

There are two types of read-only mode.

### Read-only Mode

This disables writing to the Postgres database. There's a playbook to switch it
on and off in Ansible. Documentation can be found here:
[https://github.com/pulibrary/princeton_ansible/blob/9d63e9b7f5c7af358ec439d0226372e241d490d6/playbooks/figgy_toggle_readonly.yml#L5](https://github.com/pulibrary/princeton_ansible/blob/9d63e9b7f5c7af358ec439d0226372e241d490d6/playbooks/figgy_toggle_readonly.yml#L5)

### Index Read-Only

This disables writing to the Solr index, but allows writes to the Postgres
database which don't get indexed, such as CDL charges or new user creation. This
is most useful for long reindexing operations where we want to minimally impact
our patrons.

To enable:

1. Create a PR which configures `index_read_only` in `config/config.yml` for
   production or staging and deploy the branch.
1. Deploy `main` again when reindexing is complete.

## More
Valkyrie Documentation:
- For links to helpful valkyrie documentation and troubleshooting tips, visit the [Valkyrie wiki](https://github.com/samvera-labs/valkyrie/wiki).
- Figgy documentation is in [/docs](https://github.com/pulibrary/figgy/tree/main/docs)

User documentation is maintained in Google Drive:
- [Figgy_work > Demos and Documentation](https://drive.google.com/drive/u/2/folders/1--EaoC-9fCpJx2tW4ej0-SyNNbEBX4MX)
- [Controlled Digital Lending workflow documentation](https://docs.google.com/document/d/1zX-V93TGy-2U2AF-cZb6GBrrz-J6onF1yo8UgMoSzes/edit#heading=h.up07nmqm707q)
