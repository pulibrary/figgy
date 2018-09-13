# frozen_string_literal: true
class DownloadsController < ApplicationController
  include TokenAuth
  include Hydra::Controller::DownloadBehavior

  def show
    if resource && load_file
      send_content
    else
      render_404
    end
  end

  def send_content
    prepare_file_headers
    # Necessary until a Rack version is released which allows for multiple
    # HTTP_X_ACCEL_MAPPING. When this commit is in a released version:
    # https://github.com/rack/rack/commit/f2361997623e5141e6baa907d79f1212b36fbb8b
    # remove this line and move it to the nginx configuration.
    request.env["HTTP_X_ACCEL_MAPPING"] = "/opt/repository/=/restricted_repository/"
    send_file(load_file.file.disk_path, filename: load_file.original_name, type: load_file.mime_type, disposition: :inline)
  end

  def resource
    @resource ||= query_service.find_by(id: Valkyrie::ID.new(params[:resource_id]))
  rescue Valkyrie::Persistence::ObjectNotFoundError
    nil
  end

  def load_file
    return unless binary_file && file_desc
    @load_file ||= FileWithMetadata.new(id: params[:id], file: binary_file, mime_type: file_desc.mime_type, original_name: file_desc.original_filename.first, file_set_id: resource.id)
  end

  def file_desc
    return unless resource
    @file_desc ||= resource.file_metadata.find { |m| m.id.to_s == params[:id] }
  end

  def binary_file
    return unless file_desc
    @binary_file ||= storage_adapter.find_by(id: file_desc.file_identifiers.first)
  end

  class FileWithMetadata < Dry::Struct
    delegate :size, :read, :stream, to: :file
    attribute :file, Valkyrie::Types::Any
    attribute :mime_type, Valkyrie::Types::SingleValuedString
    attribute :original_name, Valkyrie::Types::SingleValuedString
    attribute :file_set_id, Valkyrie::Types::Any
  end

  # Customize the :download ability in your Ability class, or override this method
  def authorize_download!
    authorize! :download, resource
    authorize! :download, load_file
  end

  # Copied from hydra-head and adjusted to handle the fact that we don't have a
  # modified_date in Valkyrie yet.
  def prepare_file_headers
    response.headers["Content-Type"] = file_desc.mime_type.first.to_s
    response.headers["Content-Length"] ||= binary_file.size.to_s
    # Prevent Rack::ETag from calculating a digest over body
    response.headers["Last-Modified"] = file_desc.updated_at.utc.strftime("%a, %d %b %Y %T GMT")
  end

  def query_service
    Valkyrie.config.metadata_adapter.query_service
  end

  def storage_adapter
    Valkyrie.config.storage_adapter
  end
end
