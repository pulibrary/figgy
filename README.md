# Figgy

A digital repository application in use at Princeton University Library for storing and managing digital representations of manuscripts, ephemera, vector, and raster data for export into a variety of front-end displays.

[![CircleCI](https://circleci.com/gh/pulibrary/figgy.svg?style=svg)](https://circleci.com/gh/pulibrary/figgy)
[![Browserstack](./browserstack-logo.svg)](https://www.browserstack.com/)

## Language Dependencies

Figgy provides a `.tool-versions` file -- consule this file for required languages and their current versions. `asdf` users should ensure all plugins listed there are installed:

`$ asdf plugin-add ruby`
`$ asdf plugin-add nodejs`
`$ asdf plugin-add java`

and then run `asdf install`.

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

* [Google Chrome](https://google.com/chrome/) (for feature tests)
* Postgres (for OSX dev systems, install via homebrew)
* [Redis](http://redis.io/)
    * Start Redis with `redis-server` or if you're on certain Linuxes, you can do this via `sudo service redis-server start`.
* [ImageMagick](https://www.imagemagick.org)
    * On a mac, do `brew install imagemagick`
* [RabbitMQ](https://www.rabbitmq.com/) (Optional)
    * Start with rabbitmq-server
    * Used for publishing create/update/delete events for systems such as
      [Pomegranate](https://github.com/pulibrary/pomegranate)
* [GDAL](http://www.gdal.org/)
    * You can install it on Mac OSX with `brew install gdal`.
    * On Ubuntu, use `sudo apt-get install gdal-bin`.
* [Simple Tiles](http://propublica.github.io/simple-tiles/)
    * Install via Homebrew: `brew install simple-tiles`
* [Tesseract](https://github.com/tesseract-ocr/tesseract)
    * Version 3.04 is on the servers; homebrew installs 4.1.1: `brew install tesseract-lang`
    * For Ubuntu you'll have to [compile](https://github.com/tesseract-ocr/tesseract/wiki/Compiling) it.
* [MediaInfo](https://mediaarea.net/en/MediaInfo)
    * You can install it on Mac OSX with `brew install mediainfo`.
    * On Ubuntu, use `sudo apt-get install mediainfo`.
* [FFMpeg](http://www.ffmpeg.org/)
    * Used for AV derivatives.
    * `brew install ffmpeg`
* [VIPS]
    * `brew install vips`
* [OCRmyPDF](https://ocrmypdf.readthedocs.io/)
    * `brew install ocrmypdf`

### Troubleshooting

Occasionally tests may start to give messages about not finding the gdal package, the
following steps usually resolve this issue:

1. `gem uninstall simpler-tiles`
1. `brew uninstall simple-tiles`
1. (only sometimes required) `brew uninstall gdal`
1. `brew install simple-tiles`
1. `bundle install`

This sort of dance sometimes helps with other similar errors.

## Automatically pull vault password from lastpass
More information about lastpass-cli can be found here: https://lastpass.github.io/lastpass-cli/lpass.1.html
```
brew install lastpass-cli
lpass login <email@email.com>
```

## Initial Setup

```sh
git clone https://github.com/pulibrary/figgy.git
cd figgy
`bin/setup_keys`
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
1. `bundle exec rake figgy:server:start`

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
  - `rails vocab:load CSV=config/vocab/iso639-1.csv NAME="LAE Languages"`
  - `rails vocab:load CSV=config/vocab/iso639-2.csv NAME="ISO-639-2 Languages"`
  - `rails vocab:load CSV=config/vocab/lae_areas.csv NAME="LAE Areas"`
  - `rails vocab:load CSV=config/vocab/lae_genres.csv NAME="LAE Genres" LABEL=pul_label`
  - `rails vocab:load CSV=config/vocab/lae_subjects.csv NAME="LAE Subjects" CATEGORY=category LABEL=subject`

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

## ArchivesSpace Synchronization

Figgy will persist DAOs to ArchivesSpace on completion of finding aid resources.
To set this up in development, do the following:

1. `lpass login <email>`
1. `bundle exec rake setup_keys`

## More
For links to helpful valkyrie documentation and troubleshooting tips, visit the [wiki pages](https://github.com/pulibrary/figgy/wiki).
