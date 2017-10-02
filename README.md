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
    * On a mac, do `brew install imagemagick --with-little-cms-2`
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


## Background workers

Some tasks are performed by background workers. To run a Sidekiq background worker process to execute
background jobs that are queued:

```
bundle exec sidekiq
```
