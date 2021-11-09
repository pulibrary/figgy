use Mix.Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :figx, Figx.Repo,
  username: System.get_env("FIGGY_DB_USERNAME") || "postgres",
  password: "",
  database: "figgy_test",
  hostname: "localhost",
  port: System.get_env("FIGGY_DB_PORT") || 32787,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :figx, FigxWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
