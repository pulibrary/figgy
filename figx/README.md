# Figx

FigX's goal is to replace Figgy's IIIF manifest generation with a faster and
less confusing implementation.

## Development Setup

In Figgy Directory:

1. `bundle exec rake figgy:server:start`

In Figx Directory:

1. `mix deps.get`
1. `mix test`
2. `cd assets && npm install && cd ..`

To start your Phoenix server:

  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
