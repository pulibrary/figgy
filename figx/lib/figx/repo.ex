defmodule Figx.Repo do
  use Ecto.Repo,
    otp_app: :figx,
    adapter: Ecto.Adapters.Postgres
  import Ecto.Query, only: [from: 2]

  def all_collections do
    from(Figx.Resource, where: [internal_resource: "Collection"])
    |> all()
  end

  def get_resource(id) do
    get(Figx.Resource, id)
  end
end
