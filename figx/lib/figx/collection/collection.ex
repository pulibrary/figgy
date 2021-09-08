defmodule Figx.Collection do
  alias Figx.{Repo, Resource}
  import Ecto.Query, only: [from: 2]

  def all do
    from(Resource, where: [internal_resource: "Collection"])
    |> Repo.all()
  end

  def members(id) when is_binary(id) do
    p = %{ member_of_collection_ids: [%{id: id}] }
    from(Resource, where: fragment("metadata @> ?::jsonb", ^p))
    |> Repo.all()
  end
end
