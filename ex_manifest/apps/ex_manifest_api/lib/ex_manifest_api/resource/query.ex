defmodule ExManifestApi.Resource.Query do
  import Ecto.Query
  @moduledoc """
  Documentation for ExManifestApi.Resource.Query
  """
  def members(%{id: id}) do
    ExManifestApi.Resource
    |> join(
      :cross,
      [r],
      p in fragment("jsonb_array_elements(?.metadata->'member_ids') WITH ORDINALITY", r)
    )
    |> join(:left, [r, p, z], z in ExManifestApi.Resource,
      on: fragment("(?.value->>'id')::UUID", p) == z.id
    )
    |> select([..., z], z)
    |> order_by([r, p, z], p.ordinality)
    |> where([r], r.id == ^id)
    |> ExManifestApi.Repo.all()
  end
end
