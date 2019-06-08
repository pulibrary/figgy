defmodule ExManifestApi.Repo.Migrations.CreateOrmResources do
  use Ecto.Migration

  def change do
    create table(:orm_resources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :metadata, :map
      add :internal_resource, :string
      add :lock_version, :integer

      add :created_at, :naive_datetime
      add :updated_at, :naive_datetime
    end

  end
end
