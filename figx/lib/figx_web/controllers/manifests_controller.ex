defmodule FigxWeb.ManifestsController do
  use FigxWeb, :controller

  def show(conn, _params) do
    # TODO: fetch resource
    resources = Figx.Repo.all_collections()
    resources = resources |>
    Enum.map(fn(%{id: id, metadata: %{title: title}}) -> %{id: id, label: title} end)
    render(conn, "show.json", resources)
  end
end
