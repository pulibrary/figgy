# frozen_string_literal: true
module BlacklightStubbing
  def stub_blacklight_views
    allow(view).to receive(:action_name).and_return('show')
    allow(view).to receive_messages(has_user_authentication_provider?: false)
    allow(view).to receive_messages(render_document_sidebar_partial: "Sidebar")
    allow(view).to receive_messages(current_search_session: nil)
    allow(view).to receive(:blacklight_config).and_return(CatalogController.new.blacklight_config)
    allow(view).to receive(:blacklight_configuration_context).and_return(Blacklight::Configuration::Context.new(controller))
    allow(view).to receive(:search_state).and_return(Blacklight::SearchState.new({}, CatalogController.new.blacklight_config))
    allow(view).to receive(:search_session).and_return({})
  end
end

RSpec.configure do |config|
  config.include BlacklightStubbing
end
