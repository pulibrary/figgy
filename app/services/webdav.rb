# Read-only WebDAV view of Figgy. See WebdavController and Webdav::Resolver.
module Webdav
  # Timestamp used for virtual directories (roots, title ranges, searches)
  # which have no natural modification time. A fixed value keeps clients from
  # thinking they've changed on every listing.
  VIRTUAL_MTIME = Time.utc(2000, 1, 1)

  def self.directory(name, mtime: VIRTUAL_MTIME, resource_id: nil)
    Entry.new(name: name, collection: true, size: 0, mtime: mtime, resource_id: resource_id)
  end

  # @return [FileSet, nil] the FileSet if this ability may download it
  def self.downloadable_file_set(file_set_id:, parent:, ability:)
    file_set = ChangeSetPersister.default.query_service.find_by(id: file_set_id)
    # Preload the parent so the Ability doesn't have to look it up again.
    file_set.loaded[:parents] = [parent.decorate]
    file_set if ability.can?(:download, file_set)
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  def self.downloadable?(**args)
    downloadable_file_set(**args).present?
  end
end
