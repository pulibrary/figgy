# frozen_string_literal: true
module Numismatics
  class IssuesController < BaseResourceController
    self.change_set_class = DynamicChangeSet
    self.resource_class = Numismatics::Issue
    self.change_set_persister = ::ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )

    before_action :load_numismatic_references, only: [:new, :edit]
    before_action :load_monograms, only: [:new, :edit]
    before_action :load_numismatic_places, only: [:new, :edit]
    before_action :load_numismatic_people, only: [:new, :edit]

    def load_numismatic_places
      @numismatic_places = query_service.find_all_of_model(model: Numismatics::Place).map(&:decorate)
    end

    def load_numismatic_people
      @numismatic_people = query_service.find_all_of_model(model: Numismatics::Person).map(&:decorate)
    end

    def load_numismatic_references
      @numismatic_references = query_service.find_all_of_model(model: Numismatics::Reference).map(&:decorate).sort_by(&:short_title)
    end

    def load_monograms
      @numismatic_monograms = query_service.find_all_of_model(model: Numismatics::Monogram).map(&:decorate)
      return [] if @numismatic_monograms.to_a.blank?
    end

    def manifest
      authorize! :manifest, resource
      respond_to do |f|
        f.json do
          render json: ManifestBuilder.new(resource).build
        end
      end
    end
  end
end
