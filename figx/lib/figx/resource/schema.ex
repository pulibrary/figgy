defmodule Figx.Resource do
  use Figx, :model
  alias Figx.Repo
  @primary_key {:id, :binary_id, autogenerate: false}

  schema "orm_resources" do
    field :metadata, :map
    field :internal_resource, :string
  end

  def title(%{metadata: %{"imported_metadata" => [%{"title" => title}]}}), do: title
  def title(%{metadata: %{"title" => title}}), do: title


  def description(%{metadata: %{"imported_metadata" => [%{"description" => description}]}}), do: description
  def description(%{metadata: %{"description" => description}}), do: description
  def description(_), do: nil
end
