defmodule ExManifestApiWeb.Router do
  use ExManifestApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", ExManifestApiWeb do
    pipe_through :api
  end
end
