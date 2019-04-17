# frozen_string_literal: true
class NumismaticPeopleController < BaseResourceController
  self.change_set_class = DynamicChangeSet
  self.resource_class = NumismaticPerson
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )
  before_action :load_numismatic_people, only: :index

  def index
    render "index"
  end

  private

    def load_numismatic_people
      @numismatic_people = query_service.find_all_of_model(model: NumismaticPerson).map(&:decorate)
      return [] if @numismatic_people.to_a.blank?
    end
end
