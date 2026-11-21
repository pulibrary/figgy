module Webdav
  # The contents of one resource directory, in member order:
  #
  # * child works become directories
  # * image FileSets become "0001 - page.jpg", a readable-size rendering
  #   served by the IIIF image server
  # * other FileSets (PDFs, audio, ...) become their primary file
  # * an "originals" directory holds every FileSet's primary file, for
  #   people who need the archival masters
  #
  # Derivatives follow read access, like the public viewer. Originals need
  # download access, so a resource marked "no downloads" still shows its page
  # images but has no originals directory.
  #
  # Building this means loading every member from Postgres (one query, but up
  # to tens of thousands of rows for big books), so the user-independent part
  # is cached. The cache key includes the resource's updated_at, which changes
  # whenever members are added, removed, or reordered. Changes inside a FileSet
  # (e.g. a replaced file) show up when the entry expires.
  class ResourceListing
    CACHE_TTL = 10.minutes
    ORIGINALS = "originals"
    # IIIF size parameter: longest side 2000px. Readable for text pages
    # without pulling the full-resolution master.
    DERIVATIVE_SIZE = "!2000,2000"

    attr_reader :resource, :ability
    def initialize(resource:, ability:)
      @resource = resource
      @ability = ability
    end

    # @param fetch_sizes [Boolean] false to skip asking the image server for
    #   derivative sizes it hasn't reported yet (e.g. when serving one file)
    # @return [Array<Entry>] what this user may see in the resource directory
    def entries(fetch_sizes: true)
      raw = cached_entries
      visible_dirs = readable_child_ids(raw.select(&:collection?))
      downloadable = files_downloadable?(raw.find(&:file_id))
      listed = raw.filter_map do |entry|
        if entry.collection?
          entry if visible_dirs.include?(entry.resource_id)
        elsif entry.derivative_url
          derivative_entry(entry)
        elsif downloadable
          entry
        end
      end
      listed << Webdav.directory(ORIGINALS) if downloadable && raw.any?(&:derivative_url)
      add_derivative_sizes(listed, fetch: fetch_sizes)
    end

    # @return [Array<Entry>] the originals directory, if this user may see it
    def originals
      raw = cached_entries.select(&:file_id)
      return [] unless raw.any?(&:derivative_url) && files_downloadable?(raw.first)
      raw.map { |entry| entry.dup.tap { |e| e.derivative_url = nil } }
    end

    def find(name)
      entries(fetch_sizes: false).find { |entry| entry.name == name }
    end

    def find_original(name)
      originals.find { |entry| entry.name == name }
    end

    private

      def cached_entries
        # Cached as plain hashes so unmarshalling never depends on autoloading.
        Rails.cache.fetch(cache_key, expires_in: CACHE_TTL) { build_entries.map(&:to_h) }.map { |h| Entry.new(**h) }
      end

      def cache_key
        ["webdav/v2/listing", resource.id.to_s, resource.updated_at&.to_f].join("/")
      end

      def build_entries
        members = query_service.find_members(resource: resource).reject { |m| m.is_a?(ProxyFileSet) }.to_a
        members.each_with_index.map do |member, index|
          position = Naming.position(index, members.size)
          member.is_a?(FileSet) ? file_entry(member, position) : child_entry(member, position)
        end.compact
      end

      def file_entry(file_set, position)
        file = file_set.primary_file
        return unless file
        Entry.new(
          name: Naming.file_name(filename: file.original_filename.first || file_set.title.first, position: position),
          collection: false,
          size: file.size.first.to_i,
          mtime: file.updated_at || file_set.updated_at,
          content_type: file.mime_type.first.to_s.presence || "application/octet-stream",
          file_set_id: file_set.id.to_s,
          file_id: file.id.to_s,
          derivative_url: derivative_url(file_set)
        )
      end

      # @return [String, nil] a IIIF image URL, for images the image server has
      def derivative_url(file_set)
        return unless file_set.image?
        base = ManifestBuilder::ManifestHelper.new.manifest_image_path(file_set)
        "#{base}/full/#{DERIVATIVE_SIZE}/0/default.jpg" if base.present?
      rescue Valkyrie::Persistence::ObjectNotFoundError # No pyramidal derivative yet
        nil
      end

      # Size comes later, from DerivativeSizes. Until it's known it's left out
      # (nil) rather than guessed.
      def derivative_entry(original)
        Entry.new(
          name: "#{File.basename(original.name, File.extname(original.name))}.jpg",
          collection: false,
          size: nil,
          mtime: original.mtime,
          content_type: "image/jpeg",
          file_set_id: original.file_set_id,
          derivative_url: original.derivative_url
        )
      end

      def child_entry(child, position)
        Webdav.directory(
          Naming.resource_dir_name(title: Array.wrap(child.try(:title)).first.to_s, id: child.id, position: position),
          mtime: child.updated_at || VIRTUAL_MTIME,
          resource_id: child.id.to_s
        )
      end

      def add_derivative_sizes(listed, fetch:)
        sizes = DerivativeSizes.for(listed.select(&:derivative_url), fetch: fetch)
        listed.each { |entry| entry.size = sizes[entry.derivative_url] if entry.derivative_url }
      end

      # Child works can have their own permissions, so check each one. There
      # are rarely more than a few hundred.
      def readable_child_ids(dirs)
        return Set.new if dirs.empty?
        children = query_service.find_many_by_ids(ids: dirs.map(&:resource_id))
        children.select { |child| ability.can?(:read, child) }.map { |child| child.id.to_s }.to_set
      end

      # Download rights come from the parent, so one FileSet answers for all
      # of them. Doing the full check on each of 10,000 pages would cost a
      # query per page. The full check still runs on every GET.
      def files_downloadable?(entry)
        return false unless entry
        @files_downloadable = Webdav.downloadable?(file_set_id: entry.file_set_id, parent: resource, ability: ability) if @files_downloadable.nil?
        @files_downloadable
      end

      def query_service
        ChangeSetPersister.default.query_service
      end
  end
end
