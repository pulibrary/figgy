# frozen_string_literal: true

Rails.application.config.to_prepare do
  WorkflowRegistry.register(
    resource_class: ArchivalMediaCollection,
    workflow_class: DraftPublishWorkflow
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
    workflow_class: BookWorkflow
  )

  WorkflowRegistry.register(
    resource_class: RasterResource,
    workflow_class: BookWorkflow
  )

  WorkflowRegistry.register(
    resource_class: ScannedMap,
    workflow_class: BookWorkflow
  )

  WorkflowRegistry.register(
    resource_class: ScannedResource,
    workflow_class: BookWorkflow
  )

  WorkflowRegistry.register(
    resource_class: SimpleResource,
    workflow_class: DraftPublishWorkflow
  )

  WorkflowRegistry.register(
    resource_class: VectorResource,
    workflow_class: BookWorkflow
  )
end
