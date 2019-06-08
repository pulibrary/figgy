defmodule ExManifestApi.Resource do
  use Ecto.Schema
  import Ecto.Changeset

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
end
