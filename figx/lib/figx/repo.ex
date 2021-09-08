defmodule Figx.Repo do
  use Ecto.Repo,
    otp_app: :figx,
    adapter: Ecto.Adapters.Postgres



  def get_resource(id) do
    get(Figx.Resource, id)
  end

end
