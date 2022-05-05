# frozen_string_literal: true
module Numismatics
  class AccessionsController < ResourcesController
    self.resource_class = Numismatics::Accession
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
    before_action :load_numismatic_accessions, only: :index
    before_action :load_numismatic_firms, only: [:new, :edit]
    before_action :load_numismatic_people, only: [:new, :edit]
    before_action :load_numismatic_references, only: [:new, :edit]

    def index
      render "index"
    end

    def after_create_success(_obj, _change_set)
      redirect_to numismatics_accessions_path
    end

    def after_update_success(_obj, _change_set)
      redirect_to numismatics_accessions_path
    end

    private

      def load_numismatic_accessions
        @numismatic_accessions = query_service.find_all_of_model(model: Numismatics::Accession).map(&:decorate)
      end

      def load_numismatic_firms
        @numismatic_firms = query_service.find_all_of_model(model: Numismatics::Firm).map(&:decorate)
      end

      def load_numismatic_people
        @numismatic_people = query_service.find_all_of_model(model: Numismatics::Person).map(&:decorate)
      end

      def load_numismatic_references
        @numismatic_references = query_service.find_all_of_model(model: Numismatics::Reference).map(&:decorate).sort_by(&:short_title)
      end
  end
end
