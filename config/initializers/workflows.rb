# frozen_string_literal: true

Rails.application.config.to_prepare do
  WorkflowRegistry.register(
    resource_class: SimpleResource,
    workflow_class: DraftPublishWorkflow
  )
end
