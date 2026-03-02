class IIIFSearchResults
  attr_reader :resource, :query
  def initialize(resource:, query:)
    @resource = resource
    @query = query
  end

  private

  def parent_manifest_node
    ManifestBuilder::RootNode.for(resource)
  end

  def matching_file_sets
    @matching_file_sets ||=
      begin
        ChangeSetPersister.default.query_service.custom_queries.full_text_search(id: resource.id, text: query)
      end
  end

  def hits
    @hits ||=
      begin
        matching_file_sets.map do |file_set|
          # Highlights are returned surrounded by <em> - find those words in the
          # hOCR to get their bounding boxes.
          marked_words = highlights.map { |x| x.scan(/<em>([^<]+)<\/em>/) }.flatten.map(&:downcase).uniq
          # Regex to get all the marked words.
          pattern = /\A(#{marked_words.map { |w| Regexp.escape(w) }.join("|")})[,.!;:)']?\z/i
        end
      end
  end
end
