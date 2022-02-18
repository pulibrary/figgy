# frozen_string_literal: true

class GraphqlController < ApplicationController
  class_attribute :change_set_persister
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  skip_before_action :verify_authenticity_token
  def execute
    authorize! :read, :graphql
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    result = nil
    change_set_persister.buffer_into_index do |buffered_change_set_persister|
      context = {
        ability: current_ability,
        change_set_persister: buffered_change_set_persister
      }
      result = FiggySchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    end
    render json: result
  end

  private

    # Handle form data, JSON body, or a blank value
    def ensure_hash(ambiguous_param)
      case ambiguous_param
      when String
        if ambiguous_param.present?
          ensure_hash(JSON.parse(ambiguous_param))
        else
          {}
        end
      when Hash, ActionController::Parameters
        ambiguous_param
      when nil
        {}
      else
        raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
      end
    end
end
