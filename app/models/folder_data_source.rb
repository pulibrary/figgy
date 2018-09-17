# frozen_string_literal: true
class FolderDataSource
  attr_reader :resource, :helper
  delegate :decorated_folders_with_genres, to: :resource
  def initialize(resource:, helper:)
    @resource = resource
    @helper = helper
  end

  def data
    @data ||= decorated_folders_with_genres.map do |folder|
      {
        folder_number: folder.folder_number,
        workflow_state: folder.rendered_state,
        title: folder.title,
        barcode: folder.barcode,
        genre: Array.wrap(folder.genre.try(:label)).first || folder.genre,
        actions: helper.render_to_string(partial: "catalog/folder_actions", locals: { resource: resource, folder: folder }, formats: [:html])
      }
    end
  end
end
