# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe SimpleResourcesController do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:resource_klass) { SimpleResource }
  let(:manifestable_factory) { :published_simple_resource }

  it_behaves_like "a BaseResourceController"

  # Helper method just for the test suite
  def find_resource(id)
    query_service.find_by(id: Valkyrie::ID.new(id.to_s))
  end
end
