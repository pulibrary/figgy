# Figgy

A digital repository application using [Valkyrie](https://github.com/samvera-labs/valkyrie) for persistence.
Figgy is a proof-of-concept port of [Plum](https://github.com/pulibrary/plum) to Valkyrie to explore
functionality, performance, and scalability.

## Dependencies

* Ruby
* Java (to run Solr server)
* Postgres
* [Redis](http://redis.io/)
    * Start Redis with `redis-server` or if you're on certain Linuxes, you can do this via `sudo service redis-server start`.
* [ImageMagick](https://www.imagemagick.org)
    * On a mac, do `brew install imagemagick --with-little-cms2 --with-openjpeg`
* [Kakadu](http://kakadusoftware.com/)
    * On a mac, extract the file and run the pkg installer therein (don't get distracted by the files called kdu_show)
* [RabbitMQ](https://www.rabbitmq.com/) (Optional)
    * Start with rabbitmq-server
    * Used for publishing create/update/delete events for systems such as
      [Pomegranate](https://github.com/pulibrary/pomegranate)

## Initial Setup

```sh
git clone https://github.com/pulibrary/figgy.git
cd figgy
bundle install
```

## Setup server

1. For test:
   - `RAILS_ENV=test rake db:setup`
   - `rake server:test`
   - In a separate terminal: `rspec`
2. For development:
   - ``export SECRET_KEY_BASE=`rake secret` ``
   - `rake db:setup`
   - `rake server:development`
   - In a separate terminal: `rails s`
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
  - `rails vocab:load CSV=config/vocab/iso639-1.csv NAME="LAE Languages"
  - `rails vocab:load CSV=config/vocab/iso639-2.csv NAME="ISO-639-2 Languages"
  - `rails vocab:load CSV=config/vocab/lae_areas.csv NAME="LAE Areas"
  - `rails vocab:load CSV=config/vocab/lae_genres.csv NAME="LAE Genres" LABEL=pul_label
  - `rails vocab:load CSV=config/vocab/lae_subjects.csv NAME="LAE Subjects" CATEGORY=category LABEL=subject

## More
For links to helpful valkyrie documentation and troubleshooting tips, visit the [wiki pages](https://github.com/pulibrary/figgy/wiki).