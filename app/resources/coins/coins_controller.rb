# frozen_string_literal: true
class CoinsController < BaseResourceController
  include OrangelightDocumentController

  self.change_set_class = DynamicChangeSet
  self.resource_class = Coin
  self.change_set_persister = ::ChangeSetPersister.new(
    metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
    storage_adapter: Valkyrie.config.storage_adapter
  )

  before_action :load_numismatic_accessions, only: [:new, :edit]
  before_action :load_numismatic_references, only: [:new, :edit]
  before_action :load_available_issues, only: [:new, :edit]
  before_action :selected_issue, only: [:new, :edit]

  def load_numismatic_accessions
    @numismatic_accessions = query_service.find_all_of_model(model: NumismaticAccession).map(&:decorate).sort_by(&:label)
  end

  def load_numismatic_references
    @numismatic_references = query_service.find_all_of_model(model: NumismaticReference).map(&:decorate).sort_by(&:short_title)
  end

  def load_available_issues
    @available_issues = query_service.find_all_of_model(model: NumismaticIssue).map(&:decorate).sort_by(&:issue_number)
  end

  def parent_resource
    @parent_resource ||=
      if params[:id]
        find_resource(params[:id]).decorate.parent
      elsif params[:parent_id]
        find_resource(params[:parent_id])
      end
  end

  def numismatic_issue
    parent_resource.is_a?(NumismaticIssue) ? parent_resource : nil
  end

  def selected_issue
    @selected_issue = numismatic_issue&.id.to_s
  end

  def manifest
    authorize! :manifest, resource
    respond_to do |f|
      f.json do
        render json: ManifestBuilder.new(resource).build
      end
    end
  end

  # report whether there are files
  def discover_files
    authorize! :create, resource_class
    respond_to do |f|
      f.json do
        render json: file_locator.to_h
      end
    end
  end

  def auto_ingest
    authorize! :create, resource_class
    IngestFolderJob.perform_later(directory: file_locator.folder_pathname.to_s, property: "id", id: resource.id.to_s)
    redirect_to file_manager_coin_path(params[:id])
  end

  def pdf
    change_set = change_set_class.new(find_resource(params[:id]))
    authorize! :pdf, change_set.resource
    pdf_file = change_set.resource.pdf_file

    unless pdf_file && binary_exists_for?(pdf_file)
      pdf_file = PDFGenerator.new(resource: change_set.resource, storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)).render
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        change_set.validate(file_metadata: [pdf_file])
        buffered_changeset_persister.save(change_set: change_set)
      end
    end
    redirect_path_args = { resource_id: change_set.id, id: pdf_file.id }
    redirect_path_args[:auth_token] = auth_token_param if auth_token_param
    redirect_to download_path(redirect_path_args)
  end

  def storage_adapter
    Valkyrie.config.storage_adapter
  end

  def binary_exists_for?(file_desc)
    pdf_file_binary = storage_adapter.find_by(id: file_desc.file_identifiers.first)
    !pdf_file_binary.nil?
  rescue Valkyrie::StorageAdapter::FileNotFound => error
    Valkyrie.logger.error("Failed to locate the file for the PDF FileMetadata: #{file_desc.file_identifiers.first}: #{error}")
    false
  end

  def auth_token_param
    params[:auth_token]
  end

  private

    def file_locator
      IngestFolderLocator.new(id: resource.coin_number, search_directory: "numismatics")
    end
end
