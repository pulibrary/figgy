# Figgy

A digital repository application using [Valkyrie](https://github.com/samvera-labs/valkyrie) for persistence.
Figgy is a proof-of-concept port of [Plum](https://github.com/pulibrary/plum) to Valkyrie to explore
functionality, performance, and scalability.


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
