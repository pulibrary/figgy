# Seed Figgy.
System.cmd("bundle", ["exec", "rake", "figx:seed"], env: [{"RAILS_ENV", "test"}], cd: "..")

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Figx.Repo, :manual)
