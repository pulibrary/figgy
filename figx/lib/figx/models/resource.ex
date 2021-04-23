defmodule Figx.Resource do
  use Figx, :model
  @primary_key {:id, :binary_id, autogenerate: false}

  schema "orm_resources" do
    field :metadata, :map
    field :internal_resource, :string
  end
end
