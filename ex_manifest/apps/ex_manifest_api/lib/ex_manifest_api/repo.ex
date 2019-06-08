defmodule ExManifestApi.Repo do
  use Ecto.Repo,
    otp_app: :ex_manifest_api,
    adapter: Ecto.Adapters.Postgres
end
