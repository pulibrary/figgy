defmodule ExManifestApiWeb.Router do
  use ExManifestApiWeb, :router

  pipeline :api do
    plug CORSPlug, origin: "*"
    plug :accepts, ["json"]
  end

  scope "/", ExManifestApiWeb do
    pipe_through :api
    get "/:id/manifest", ResourceController, :manifest
  end
end
