# frozen_string_literal: true
class AddEphemeraToCollection
  attr_reader :project_id, :collection_id, :change_set_persister, :logger, :query_service
  def initialize(project_id:, collection_id:, change_set_persister:, logger: Valkyrie.logger)
    @project_id = project_id
    @collection_id = collection_id
    @change_set_persister = change_set_persister
    @logger = logger
    @query_service = Valkyrie.config.metadata_adapter.query_service
  end

  def add_box(box)
    logger.info("Processing a box: #{box.decorate.title}")
    box.decorate.members.each do |folder|
      add_folder(folder)
    end
  end

  def add_folder(folder)
    logger.info("Processing a folder: #{folder.decorate.title.first}")
    collection = query_service.find_by(id: collection_id)
    col_ids = folder.member_of_collection_ids + [collection.id]
    change_set = ChangeSet.for(folder)
    if change_set.validate(member_of_collection_ids: col_ids)
      change_set_persister.save(change_set: change_set)
    else
      logger.error("change set didn't validate for #{folder.decorate.title.first}; not added to collection")
    end
  end

  def add_ephemera
    project = query_service.find_by(id: project_id)
    collection = query_service.find_by(id: collection_id)
    logger.info("Adding members of Ephemera Project #{project.decorate.title} to Collection #{collection.decorate.title}")
    project.decorate.boxes.map { |box| add_box(box) }
    project.decorate.folders.map { |folder| add_folder(folder) }
  end
end
