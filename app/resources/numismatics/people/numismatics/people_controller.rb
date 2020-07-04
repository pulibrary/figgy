# frozen_string_literal: true
module Numismatics
  class PeopleController < BaseResourceController
    self.resource_class = Numismatics::Person
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
    before_action :load_numismatic_people, only: :index

    def index
      render "index"
    end

    def after_create_success(_obj, _change_set)
      redirect_to numismatics_people_path
    end

    def after_update_success(_obj, _change_set)
      redirect_to numismatics_people_path
    end

    private

      def load_numismatic_people
        @numismatic_people = query_service.find_all_of_model(model: Numismatics::Person).map(&:decorate)
        return [] if @numismatic_people.to_a.blank?
      end
  end
end
