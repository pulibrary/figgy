module Webdav
  # Turns a path under /dav into a node: a directory with a lazy child list,
  # or a file.
  #
  #   /                                   titles, collections, recent
  #   /titles/<range>…/                   every top-level resource you can see,
  #                                       split into title range folders
  #   /collections/<range>…/<Coll [id]>/<range>…/
  #                                       the same, per collection
  #   /recent/                            200 most recently updated
  #   …/<Title [id]>/                     a resource: child works and files
  #   …/<Title [id]>/<0001 - Child [id]>/ child works nest
  #   …/<Title [id]>/<0001 - page.jpg>    an image, as a IIIF derivative
  #   …/<Title [id]>/<0001 - file.pdf>    any other file, as the original
  #   …/<Title [id]>/originals/<file>     original files
  #
  # The last "[id]" segment decides which resource a path points to, and range
  # folders are rebuilt from their own names. So resolving any path costs at
  # most one Postgres lookup and one Solr query, no matter how deep it is.
  class Resolver
    ROOTS = %w[titles collections recent].freeze
    TOP_LEVEL = ["-internal_resource_ssim:Collection"].freeze
    COLLECTIONS = ["internal_resource_ssim:Collection"].freeze

    DirNode = Struct.new(:entry, :loader) do
      def collection?
        true
      end

      def children
        @children ||= loader.call
      end
    end

    FileNode = Struct.new(:entry, :parent) do
      def collection?
        false
      end
    end

    attr_reader :ability
    def initialize(ability:)
      @ability = ability
    end

    # @param segments [Array<String>] decoded path segments below /dav
    # @return [DirNode, FileNode, nil]
    def resolve(segments)
      # Desktop clients constantly probe for .DS_Store, ._resource-forks,
      # .localized, .hidden, etc. Answer those without touching the database.
      return if segments.any? { |s| s.start_with?(".") }
      return root if segments.empty?
      head, *rest = segments
      case head
      when "titles" then walk_tree(dir(head) { index.title_range(TitleRange.root, fq: TOP_LEVEL) }, rest, fq: TOP_LEVEL)
      when "collections" then walk_collections(rest)
      when "recent" then rest.empty? ? dir(head) { index.recent(fq: TOP_LEVEL) } : walk_resources(rest)
      end
    end

    private

      def root
        dir("") { ROOTS.map { |name| Webdav.directory(name) } }
      end

      # Range folders, then (optionally) a resource path.
      def walk_tree(tree_root, segments, fq:, index: self.index)
        ranges = segments.take_while { |s| Naming.resource_id(s).nil? }
        rest = segments.drop(ranges.size)
        node = if ranges.empty?
                 tree_root
        else
                 range = TitleRange.parse(ranges.last)
                 return unless range
                 dir(ranges.last) { index.title_range(range, fq: fq) }
        end
        rest.empty? ? node : walk_resources(rest)
      end

      def walk_collections(segments)
        tree = dir("collections") { collection_index.title_range(TitleRange.root, fq: COLLECTIONS) }
        ranges = segments.take_while { |s| Naming.resource_id(s).nil? }
        rest = segments.drop(ranges.size)
        return walk_tree(tree, ranges, fq: COLLECTIONS, index: collection_index) if rest.empty?

        collection_segment = rest.shift
        collection = find_readable(Naming.resource_id(collection_segment))
        return unless collection.is_a?(Collection)
        fq = ["member_of_collection_ids_ssim:id-#{collection.id}"]
        tree = dir(collection_segment, mtime: collection.updated_at) { index.title_range(TitleRange.root, fq: fq) }
        walk_tree(tree, rest, fq: fq)
      end

      # "<Title [id]>/<Child [id]>/…/[originals/]<file>"
      def walk_resources(segments)
        ids = segments.take_while { |s| Naming.resource_id(s) }
        rest = segments.drop(ids.size)
        return if ids.empty?

        resource = find_readable(Naming.resource_id(ids.last))
        return if resource.nil? || resource.is_a?(FileSet)
        listing = ResourceListing.new(resource: resource, ability: ability)
        case rest
        in []
          dir(ids.last, mtime: resource.updated_at) { listing.entries }
        in [ResourceListing::ORIGINALS]
          dir(ResourceListing::ORIGINALS, mtime: resource.updated_at) { listing.originals } if listing.originals.present?
        in [ResourceListing::ORIGINALS, name]
          file_node(listing.find_original(name), resource)
        in [name]
          file_node(listing.find(name), resource)
        else
          nil
        end
      end

      def file_node(entry, resource)
        FileNode.new(entry, resource) if entry && !entry.collection?
      end

      def find_readable(id)
        resource = ChangeSetPersister.default.query_service.find_by(id: id)
        resource if ability.can?(:read, resource)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      def dir(name, mtime: nil, &loader)
        DirNode.new(Webdav.directory(name, mtime: mtime || VIRTUAL_MTIME), loader)
      end

      def index
        @index ||= Index.new(ability: ability)
      end

      # Collections have no workflow state, and the catalog's state filter
      # lets them through by has_model_ssim, which Collection documents don't
      # have. Leave that filter out when listing collections.
      def collection_index
        @collection_index ||= Index.new(ability: ability, skip_processors: [:hide_incomplete])
      end
  end
end
