class PulmapIndexer
  def index(document:, commit: true)
    connection.update(
      params: { overwrite: true },
      data: "[#{document}]",
      headers: { "Content-Type" => "application/json" }
    )
    connection.commit if commit
  end

  def delete(slug:, commit: true)
    connection.delete_by_query("layer_slug_s:#{RSolr.solr_escape(slug)}")
    connection.commit if commit
  end

  private

    def connection
      @connection ||= RSolr.connect(url: Figgy.config["pulmap"]["solr_url"])
    end
end
