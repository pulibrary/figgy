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
        actions: actions(folder)
      }
    end
  end

  def actions(folder)
    folder_url = helper.solr_document_path(folder.id.to_s)
    helper.tag.td do
      helper.link_to("View", folder_url, class: "btn btn-default") +
        helper.link_to("Edit", helper.polymorphic_path([:edit, folder]), class: "btn btn-secondary")
    end
  end
end
