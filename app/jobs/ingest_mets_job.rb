# frozen_string_literal: true
class IngestMETSJob < ApplicationJob
  queue_as :ingest
  attr_reader :mets

  # @param [String] mets_file Filename of a METS file to ingest
  # @param [String] user User to ingest as
  def perform(mets_file, user)
    logger.info "Ingesting METS #{mets_file}"
    @mets = METSDocument::Factory.new(mets_file).new
    @user = user
    changeset_persister.buffer_into_index do |buffered_persister|
      Ingester.for(mets: @mets, user: @user, changeset_persister: buffered_persister).ingest
    end
  end

  def changeset_persister
    @changeset_persister ||= PlumChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def storage_adapter
    Valkyrie.config.storage_adapter
  end

  class Ingester
    delegate :metadata_adapter, to: :changeset_persister
    delegate :query_service, to: :metadata_adapter
    def self.for(mets:, user:, changeset_persister:)
      new(mets: mets, user: user, changeset_persister: changeset_persister)
    end

    attr_reader :mets, :user, :changeset_persister
    def initialize(mets:, user:, changeset_persister:)
      @mets = mets
      @user = user
      @changeset_persister = changeset_persister
    end

    def ingest
      resource.source_metadata_identifier = mets.bib_id
      resource.files = files.to_a
      resource.sync
      output = changeset_persister.save(change_set: resource)
      files.each_with_index do |file, index|
        mets_to_repo_map[file.id] = output.member_ids[index]
      end
      new_resource = DynamicChangeSet.new(output)
      new_resource.logical_structure = [{ label: "Main Structure", nodes: map_fileids(mets.structure)[:nodes] }]
      new_resource.sync
      changeset_persister.save(change_set: new_resource)
    end

    def files
      mets.files.lazy.map do |file|
        file[:path] = tmp_file(file).path
        mets.decorated_file(file)
      end
    end

    def tmp_file(file)
      basename = Pathname.new(file[:path]).basename
      Tempfile.new([basename.to_s.split(".").first, basename.extname]).tap do |f|
        FileUtils.cp(File.open(file[:path]).path, f.path)
        f.rewind
      end
    end

    def resource
      @resource ||=
        begin
          DynamicChangeSet.new(ScannedResource.new)
        end
    end

    def map_fileids(hsh)
      hsh.each do |k, v|
        hsh[k] = v.each { |node| map_fileids(node) } if k == :nodes
        hsh[k] = mets_to_repo_map[v] if k == :proxy
      end
    end

    def mets_to_repo_map
      @mets_to_repo_map ||= {}
    end
  end
end
