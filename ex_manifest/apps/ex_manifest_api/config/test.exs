use Mix.Config

# Configure your database
config :ex_manifest_api, ExManifestApi.Repo,
  database: "ex_manifest_api_test",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :ex_manifest_api, ExManifestApiWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
