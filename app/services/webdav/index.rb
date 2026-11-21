module Webdav
  # Solr-backed listings for the browse directories (titles, collections,
  # recent). Every query starts from the catalog's SearchBuilder, so
  # access controls, workflow state, suppressed resources, and the "no child
  # works or FileSets at the top level" rules match exactly what the user would
  # see in the Figgy catalog.
  class Index
    # Largest number of resources listed directly in one directory before it's
    # split into title range folders.
    LEAF_SIZE = 1000
    # Largest number listed when a range can't split any further (e.g. a
    # thousand resources all titled "Untitled").
    MAX_LEAF_SIZE = 10_000
    # The recent directory is capped instead of paged.
    RESULT_LIMIT = 200
    # Ranges this deep stop splitting. Guards against huge chains of
    # identically titled resources.
    MAX_PREFIX_LENGTH = 40
    FIELDS = "id,figgy_title_ssi,updated_at_dtsi"

    Scope = Struct.new(:blacklight_config, :current_ability, :search_state_class)

    attr_reader :ability, :skip_processors
    # @param skip_processors [Array<Symbol>] SearchBuilder steps to leave out
    def initialize(ability:, skip_processors: [])
      @ability = ability
      @skip_processors = skip_processors
    end

    # List one title range: either its resources, or the sub-ranges inside it.
    # A sub-range holding everything its parent does gets skipped, so a long
    # shared prefix doesn't make you click through one folder per letter.
    # @param fq [Array<String>] extra Solr filters (e.g. collection membership)
    # @return [Array<Entry>]
    def title_range(range, fq: [])
      loop do
        total, counts = range_counts(range, fq)
        non_empty = counts.select { |_child, count| count.positive? }
        # Small enough to list, or can't usefully split any further (e.g.
        # every title here is identical as far as the sort field goes).
        if total <= LEAF_SIZE || non_empty.empty? || range.prefix.length >= MAX_PREFIX_LENGTH
          return resources(fq: fq + [range.solr_filter].compact, sort: "title_ssort asc, id asc", rows: total)
        end
        return non_empty.map { |child, _count| Webdav.directory(child.name) } unless non_empty.size == 1
        range = non_empty.first.first
      end
    end

    def recent(fq: [])
      resources(fq: fq, sort: "updated_at_dtsi desc", rows: RESULT_LIMIT)
    end

    private

      def range_counts(range, fq)
        children = range.children
        params = filter_params(fq + [range.solr_filter].compact)
        params.merge!(
          rows: 0,
          facet: true,
          "facet.field": [],
          "facet.query": children.each_with_index.map { |child, i| "{!key=r#{i}}#{child.solr_filter}" }
        )
        response = repository.search(params)
        facet_counts = response.dig("facet_counts", "facet_queries") || {}
        [
          response["response"]["numFound"],
          children.each_with_index.map { |child, i| [child, facet_counts["r#{i}"].to_i] }
        ]
      end

      def resources(fq:, sort:, rows:)
        params = filter_params(fq)
        params.merge!(rows: [rows, MAX_LEAF_SIZE].min, sort: sort, fl: FIELDS)
        docs_to_entries(repository.search(params)["response"]["docs"])
      end

      def docs_to_entries(docs)
        docs.map do |doc|
          Webdav.directory(
            Naming.resource_dir_name(title: doc["figgy_title_ssi"], id: doc["id"]),
            mtime: (Time.zone.parse(doc["updated_at_dtsi"]) if doc["updated_at_dtsi"]) || VIRTUAL_MTIME,
            resource_id: doc["id"]
          )
        end
      end

      # A match-all query restricted by the catalog's access and visibility
      # filters, plus our own.
      def filter_params(fq)
        {
          q: "*:*",
          defType: "lucene",
          fq: access_filters + fq,
          facet: false
        }
      end

      # The catalog's filter queries for this user.
      def access_filters
        @access_filters ||= begin
          user_params = { "webdav" => "true" } # SearchBuilder skips state filtering for empty params
          builder = SearchBuilder.new(Scope.new(blacklight_config, ability, Blacklight::SearchState)).except(*skip_processors).with(user_params)
          Array.wrap(builder.to_hash.with_indifferent_access[:fq])
        end
      end

      def blacklight_config
        CatalogController.blacklight_config
      end

      def repository
        @repository ||= blacklight_config.repository_class.new(blacklight_config)
      end
  end
end
