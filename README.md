# Figgy

A digital repository application in use at Princeton University Library for storing and managing digital representations of manuscripts, ephemera, vector, and raster data for export into a variety of front-end displays.

[![CircleCI](https://circleci.com/gh/pulibrary/figgy.svg?style=svg)](https://circleci.com/gh/pulibrary/figgy)
[![Coverage Status](https://coveralls.io/repos/pulibrary/figgy/badge.svg?branch=master&service=github)](https://coveralls.io/github/pulibrary/figgy?branch=master)
[![Browserstack](./browserstack-logo.svg)](https://www.browserstack.com/)

## Dependencies

* Ruby
* Node v.8.2.1
* Java (to run Solr server)
* Postgres (for OSX dev systems, install via homebrew)
* [Redis](http://redis.io/)
    * Start Redis with `redis-server` or if you're on certain Linuxes, you can do this via `sudo service redis-server start`.
* [ImageMagick](https://www.imagemagick.org)
    * On a mac, do `brew install imagemagick`
* [Kakadu](http://kakadusoftware.com/)
    * On a mac, extract the file and run the pkg installer therein (don't get distracted by the files called kdu_show)
* [RabbitMQ](https://www.rabbitmq.com/) (Optional)
    * Start with rabbitmq-server
    * Used for publishing create/update/delete events for systems such as
      [Pomegranate](https://github.com/pulibrary/pomegranate)
* [GDAL](http://www.gdal.org/)
    * You can install it on Mac OSX with `brew install gdal`.
    * On Ubuntu, use `sudo apt-get install gdal-bin`.
* [Tesseract](https://github.com/tesseract-ocr/tesseract)
    * Version 3.04 is on the servers; homebrew installs 3.05: `brew install
      tesseract --with-all-languages`
    * For Ubuntu you'll have to [compile](https://github.com/tesseract-ocr/tesseract/wiki/Compiling) it.
* [MediaInfo](https://mediaarea.net/en/MediaInfo)
    * You can install it on Mac OSX with `brew install mediainfo`.
    * On Ubuntu, use `sudo apt-get install mediainfo`.
* [FreeTDS]
    * Needed for migration of music reserve data; we'll likely remove this dependency once that's all done
    * `brew install FreeTDS`
* [FFMpeg](http://www.ffmpeg.org/)
    * Used for AV derivatives.
    * `brew install ffmpeg`
* [VIPS]
    * `brew install vips`
* [OCRmyPDF](https://ocrmypdf.readthedocs.io/)
    * `brew install ocrmypdf`

## Simple Tiles

Figgy requires the image generation library [Simple Tiles](http://propublica.github.io/simple-tiles/).

Mac OS X:

* Install via Homebrew: ```brew install simple-tiles```

Linux:

* Install dependencies:

  ```
  apt-get install gdal-bin libgdal-dev libcairo2-dev libpango1.0-dev
  ```

* Compile:

  ```
  git clone git@github.com:propublica/simple-tiles.git
  cd simple-tiles
  ./configure
  make && make install
  ```
  * Python:

    Should you receive the following error during the installation...

    ```
    TypeError: unsupported operand type(s) for +: 'dict_items' and 'list' make: *** [install] Error 2
    ```

    ...please know that you must downgrade to the latest stable release of Python 2.x.

## Initial Setup

```sh
git clone https://github.com/pulibrary/figgy.git
cd figgy
bundle install
yarn install
```

Remember you'll need to run `bundle install` and `yarn install` on an ongoing basis as dependencies are updated.

## Setup server

### Manual Setup

1. For test:
   - `RAILS_ENV=test rake db:setup`
   - `rake figgy:test`
   - In a separate terminal: `bundle exec rspec`
   - Run jest tests: `yarn test`
2. For development:
   - ``export SECRET_KEY_BASE=`rake secret` ``
   - `rake db:setup`
   - In a separate terminal: `foreman start`
     - Or run services separately as shown in [[https://github.com/pulibrary/figgy/blob/master/Procfile]]
     - If you run into problems with `solr_wrapper`, you can also start Solr with `rake figgy:development`
   - Access Figgy at http://localhost:3000/

### Lando

1. Uninstall Docker
2. Install Lando v3.0.0-rrc.4 or later DMG from [[https://github.com/lando/lando/releases]]
3. `lando start`

1. For test:
   - `RAILS_ENV=test rake db:setup`
   - In a separate terminal: `bundle exec rspec`
   - Run jest tests: `yarn test`
2. For development:
   - ``export SECRET_KEY_BASE=`rake secret` ``
   - `rake db:setup`
   - In a separate terminal: `foreman start` (you can close the one launching solr)
     - Or run services separately as shown in [[https://github.com/pulibrary/figgy/blob/master/Procfile]]
   - Access Figgy at http://localhost:3000/

## Load sample development data

1. Log in to your development instance using your princeton credentials; this creates your user in figgy's db.
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

## More
For links to helpful valkyrie documentation and troubleshooting tips, visit the [wiki pages](https://github.com/pulibrary/figgy/wiki).
