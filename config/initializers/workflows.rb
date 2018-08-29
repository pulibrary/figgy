# frozen_string_literal: true

Rails.application.config.to_prepare do
  WorkflowRegistry.register(
    resource_class: ArchivalMediaCollection,
<<<<<<< HEAD
    workflow_class: DraftCompleteWorkflow
=======
    workflow_class: DraftPublishWorkflow
>>>>>>> d8616123... adds lux order manager to figgy
  )

  WorkflowRegistry.register(
    resource_class: EphemeraFolder,
    workflow_class: FolderWorkflow
  )

  WorkflowRegistry.register(
    resource_class: EphemeraBox,
    workflow_class: BoxWorkflow
  )

  WorkflowRegistry.register(
    resource_class: MediaResource,
<<<<<<< HEAD
    workflow_class: DraftCompleteWorkflow
=======
    workflow_class: DraftPublishWorkflow
>>>>>>> d8616123... adds lux order manager to figgy
  )

  WorkflowRegistry.register(
    resource_class: RasterResource,
    workflow_class: GeoWorkflow
  )

  WorkflowRegistry.register(
    resource_class: ScannedMap,
    workflow_class: GeoWorkflow
  )

  WorkflowRegistry.register(
    resource_class: ScannedResource,
    workflow_class: BookWorkflow
  )

  WorkflowRegistry.register(
    resource_class: SimpleResource,
<<<<<<< HEAD
    workflow_class: DraftCompleteWorkflow
=======
    workflow_class: DraftPublishWorkflow
>>>>>>> d8616123... adds lux order manager to figgy
  )

  WorkflowRegistry.register(
    resource_class: VectorResource,
    workflow_class: GeoWorkflow
  )
end
