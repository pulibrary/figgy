defmodule ExManifestApi.Resource do
  @moduledoc """
  Documentation for ExManifestApi.Resource
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "orm_resources" do
    field :internal_resource, :string
    field :lock_version, :integer
    field :metadata, :map
    field :created_at, :naive_datetime
    field :updated_at, :naive_datetime
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:id, :metadata, :internal_resource, :lock_version])
    |> validate_required([:id, :metadata, :internal_resource, :lock_version])
  end

  def to_manifest(resource) do
    %ExIiifManifest.Resource{
      id: resource.id |> to_manifest_url,
      label: hd(resource.metadata.title),
      canvas_nodes: resource |> members |> Enum.map(&to_image_node/1)
    }
  end

  defp to_manifest_url(id) do
    "https://test.com/#{id}/manifest"
  end

  def members(%{id: id}) do
    ExManifestApi.Resource
    |> join(
      :cross,
      [r, p],
      p in fragment("jsonb_array_elements(?.metadata->'member_ids') WITH ORDINALITY", r)
    )
    |> join(:left, [r, p, z], z in ExManifestApi.Resource, on: fragment("(?.value->>'id')::UUID", p) == z.id)
    |> select([r, p, z], {z})
    |> order_by([r, p, z], p.ordinality)
    |> where([r], r.id == ^id)
    |> ExManifestApi.Repo.all()
    |> Enum.map(&elem(&1, 0))
  end

  defp to_image_node(file_set = %{internal_resource: "FileSet"}) do
    %ExIiifManifest.ImageNode{}
  end
end
