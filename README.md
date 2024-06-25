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
* [tippecanoe](https://github.com/felt/tippecanoe) vector tileset generator

Other dependencies:

* Postgres (for OSX dev systems, install via homebrew)
* [Redis](http://redis.io/)
    * Start Redis with `redis-server` or if you're on certain Linuxes, you can do this via `sudo service redis-server start`.
* [RabbitMQ](https://www.rabbitmq.com/) (Optional)
    * Start with rabbitmq-server
    * Used for publishing create/update/delete events for systems such as
      [Pomegranate](https://github.com/pulibrary/pomegranate)

## Initial Setup

```sh
git clone https://github.com/pulibrary/figgy.git
cd figgy
./bin/setup_asdf
Follow setup notes for Mac M series processors if needed
./bin/setup
```

Remember you'll need to run `bundle install` and `yarn install` on an ongoing basis as dependencies are updated.

### Setup Notes for Mac M Series Processors

Mapnik currently isn't supported by M1 processors, so `yarn install` above will
fail. To get this working, do the following:

1. Install Rosetta: `/usr/sbin/softwareupdate --install-rosetta --agree-to-license`
1. Right click the "Terminal" app in Finder, go to "Get Info", and check "Open
   using Rosetta"
1. Open Terminal, go to this directory
1. `asdf uninstall nodejs`
1. `asdf uninstall yarn`
1. `rm ~/.asdf/shims/yarn`
1. `asdf install nodejs`
1. `npm install -g yarn`
1. `yarn install`
1. Close Terminal, right click "Terminal" app in Finder, go to "Get Info", and
   uncheck "Open using Rosetta"
1. Add the following to `~/.zshrc` or `~/.zshrc.local`:
```
   # Fix issue with homebrew postgres and rails applications (Figgy in
   particular).
   # See: https://github.com/ged/ruby-pg/issues/538
   export PGGSSENCMODE="disable"
```

## Populate sidekiq-pro credentials from lastpass

These steps are performed by `./bin/setup`; if that worked you don't have to do
this separately.

More information about lastpass-cli can be found here: https://lastpass.github.io/lastpass-cli/lpass.1.html
```
brew install lastpass-cli
lpass login <email@email.com>
bin/setup_credentials
```

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
   - Run javascript tests: `yarn test`
1. For development:
   - In a separate terminal: `bundle exec foreman start`
     - Or run services separately as shown in [[https://github.com/pulibrary/figgy/blob/main/Procfile]]
   - Access Figgy at http://localhost:3000/

### Feature Tests

If you want to watch feature tests run for debugging purposes, you can go to
http://localhost:7900, use the password `secret`, and run tests like this:

`RUN_IN_BROWSER=true bundle exec rspec spec/features`

### Parallel Tests

If you'd like to run the test suite in parallel do the following:

1. `bundle exec rake servers:start`
1. `PARALLEL_TEST_FIRST_IS_1=true RAILS_ENV=test rake parallel:setup` (Sets up suport database; only needed after db has been destroyed)
1. `./bin/parallel_rspec_coverage`

The output from the parallel runs will be interspersed, and the failures will be
listed separately for each parallel run, but final run time and coverage will be
reported accurate, and the file that powers the --only-failures flag will be
correctly generated.

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

## Preservation Configuration in Development

Figgy uses Google Cloud Storage buckets for providing support for preserving certain resources.  Please find further documentation outlining the configuration for Google Cloud service authentication and permissions management [here](https://github.com/pulibrary/figgy/blob/master/GOOGLE_CLOUD_STORAGE.md).

By default, in development, preserved objects will be stored in the directory
"tmp/cloud_backup." If you'd like to configure and test Google Cloud storage
instead, do the following:

1. Download, ansible-vault decrypt, and save gcs_pulibrary-staging-credentials.json from https://github.com/pulibrary/princeton_ansible/blob/main/roles/figgy/files/staging-google_cloud_credentials.json (rename to gcs_pulibrary-staging-credentials.json)
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
in [preservation_documentation.md](/docs/technical/preservation/google_pub_sub.md).

### Deployment Steps

1. `gcloud components install beta`
1. `gcloud auth login`
1. `gcloud config set project pulibrary-figgy-storage-1`
1. `cap [staging/production] deploy:google_cloud_function`

## ArchivesSpace Synchronization and TiTiler functionality

Figgy will persist DAOs to ArchivesSpace on completion of finding aid resources.
It also uses an s3 bucket to store geo derivatives and serve them via titiler

To set these up in development, do the following:

1. `lpass login <email>`
1. `bundle exec rake figgy:setup_keys`

## Read-only Maintenance Windows

There are two types of read-only mode.

### Read-only Mode

Read-only mode disables writing to the Postgres database. Use princeton_ansible to activate it:
* change the `figgy_read_only_mode` value in the relevant group_vars file (example: https://github.com/pulibrary/princeton_ansible/blob/9ccaadf336ddac973c4c18e836d46d445f15d38f/group_vars/figgy/staging.yml#L30)
* run the figgy playbook on the relevant environment using the command line switch `--tags=site_config` (this will also restart the site; visit it in browser to confirm)
* run the 'sidekiq:restart' cap task for the relevant environment to ensure workers all have the switch loaded correctly

Known issue: In read-only mode users cannot download pdfs (unless they've been cached). See #2866

### Index Read-Only

This disables writing to the Solr index, but allows writes to the Postgres
database which don't get indexed, such as CDL charges or new user creation. This
is most useful for long reindexing operations where we want to minimally impact
our patrons.

To enable:

1. Create a PR which configures `index_read_only` in `config/config.yml` for
   production or staging and deploy the branch.
1. Deploy `main` again when reindexing is complete.

## Maintaining CircleCI base image

We maintain a Figgy Docker image for use in CircleCI. The Dockerfile is
located in the `.circleci` directory. To update a package, dependency, or ruby
version, make edits to the Dockerfile. Then build and push the image to Docker Hub using
the following steps (be sure to increment the version):

```
cd .circleci/
docker login # login to docker hub
docker buildx build --push --platform linux/arm64,linux/amd64 -t pulibrary/ci-figgy:{version} . -f ./.circleci/Dockerfile
docker push pulibrary/ci-figgy:{version}
```


## More
Valkyrie Documentation:
- For links to helpful valkyrie documentation and troubleshooting tips, visit the [Valkyrie wiki](https://github.com/samvera-labs/valkyrie/wiki).
- Figgy documentation is in [/docs](https://github.com/pulibrary/figgy/tree/main/docs)

User documentation is maintained in Google Drive:
- [Figgy_work > Demos and Documentation](https://drive.google.com/drive/u/2/folders/1--EaoC-9fCpJx2tW4ej0-SyNNbEBX4MX)
- [Controlled Digital Lending workflow documentation](https://docs.google.com/document/d/1zX-V93TGy-2U2AF-cZb6GBrrz-J6onF1yo8UgMoSzes/edit#heading=h.up07nmqm707q)
