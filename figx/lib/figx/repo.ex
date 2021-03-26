defmodule Figx.Repo do
  use Ecto.Repo,
    otp_app: :figx,
    adapter: Ecto.Adapters.Postgres
end
