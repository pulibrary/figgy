# frozen_string_literal: true
module Numismatics
  class FirmsController < ResourceController
    self.resource_class = Numismatics::Firm
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
    before_action :load_numismatic_firms, only: :index

    def index
      render "index"
    end

    def after_create_success(_obj, _change_set)
      redirect_to numismatics_firms_path
    end

    def after_update_success(_obj, _change_set)
      redirect_to numismatics_firms_path
    end

    private

      def load_numismatic_firms
        @numismatic_firms = query_service.find_all_of_model(model: Numismatics::Firm).map(&:decorate)
        return [] if @numismatic_firms.to_a.blank?
      end
  end
end
