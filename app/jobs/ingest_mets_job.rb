# frozen_string_literal: true
class IngestMETSJob < ApplicationJob
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
    @changeset_persister ||= PlumChangeSetPersister.new(metadata_adapter: metadata_adapter,
                                                        storage_adapter: storage_adapter,
                                                        queue: queue_name)
  end

  def metadata_adapter
    Valkyrie::MetadataAdapter.find(:indexing_persister)
  end

  def storage_adapter
    Valkyrie::StorageAdapter.find(:disk_via_copy)
  end

  class Ingester
    delegate :metadata_adapter, to: :changeset_persister
    delegate :query_service, to: :metadata_adapter
    def self.for(mets:, user:, changeset_persister:)
      if mets.multi_volume?
        HierarchicalIngester.new(mets: mets, user: user, changeset_persister: changeset_persister)
      else
        new(mets: mets, user: user, changeset_persister: changeset_persister)
      end
    end

    attr_reader :mets, :user, :changeset_persister
    def initialize(mets:, user:, changeset_persister:)
      @mets = mets
      @user = user
      @changeset_persister = changeset_persister
    end

    def ingest
      resource.source_metadata_identifier = mets.bib_id
      resource.title = mets.label
      resource.files = files.to_a
      resource.sync
      output = changeset_persister.save(change_set: resource)
      files.each_with_index do |file, index|
        mets_to_repo_map[file.id] = output.member_ids[index]
      end
      assign_logical_structure(output)
    end

    def assign_logical_structure(output)
      new_resource = DynamicChangeSet.new(output)
      new_resource.logical_structure = [{ label: "Main Structure", nodes: map_fileids(mets.structure)[:nodes] }]
      new_resource.sync
      changeset_persister.save(change_set: new_resource)
    end

    def files
      mets.files.lazy.map do |file|
        mets.decorated_file(file)
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

  class HierarchicalIngester < Ingester
    def ingest
      resource.source_metadata_identifier = mets.bib_id
      mets.volume_ids.each do |volume_id|
        volume_mets = VolumeMets.new(parent_mets: mets, volume_id: volume_id)
        volume = Ingester.new(mets: volume_mets, user: user, changeset_persister: changeset_persister).ingest
        resource.member_ids = resource.member_ids + [volume.id]
      end
      resource.sync
      changeset_persister.save(change_set: resource)
    end
  end

  class VolumeMets
    attr_reader :parent_mets, :volume_id
    delegate :decorated_file, to: :parent_mets
    def initialize(parent_mets:, volume_id:)
      @parent_mets = parent_mets
      @volume_id = volume_id
    end

    def bib_id
      nil
    end

    def files
      parent_mets.files_for_volume(volume_id)
    end

    def structure
      parent_mets.structure_for_volume(volume_id)
    end

    def label
      parent_mets.label_for_volume(volume_id)
    end
  end
end
