# frozen_string_literal: true
class PlumImporter
  attr_reader :id, :change_set_persister
  attr_writer :all_collections, :id_cache
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  delegate :delayed_queue, to: :change_set_persister
  def initialize(id:, change_set_persister:, logger: Rails.logger)
    @id = id
    @change_set_persister = change_set_persister
    @logger = logger
  end

  def import!
    output = change_set_persister.save(change_set: change_set)
    id_cache[id] = output.id.to_s
    members = query_service.find_members(resource: output).to_a
    file_sets = members.select { |x| x.is_a?(FileSet) }
    file_sets.each do |member|
      id_cache[member.local_identifier.first] = member.id.to_s
      import_derivative(member)
      add_checksums(member)
    end
    update_structure(output, members, change_set_persister)
  end

  def add_checksums(member)
    delayed_queue.add do
      GenerateChecksumJob.set(queue: :low).perform_later(member.id.to_s)
    end
  end

  def import_derivative(member)
    file_change_set = FileSetChangeSet.new(member)
    file_change_set.prepopulate!
    file_change_set.files = [derivative(member)]
    derivative_change_set_persister = change_set_persister.class.new(
      metadata_adapter: change_set_persister.metadata_adapter,
      storage_adapter: derivative_storage_adapter,
      handlers: change_set_persister.handlers
    )
    derivative_change_set_persister.save(change_set: file_change_set)
  rescue Errno::ENOENT
    generate_derivative(member)
  end

  def generate_derivative(member)
    delayed_queue.add do
      CreateDerivativesJob.set(queue: :low).perform_later(member.id.to_s)
    end
  end

  def logical_structure_from(values)
    MultiJson.load(values, symbolize_keys: true)
  rescue StandardError => error
    @logger.warn "Failed to parse the logical structure while importing #{resource.id}: #{error}"
    {}
  end

  def update_structure(resource, members, change_set_persister)
    change_set = ScannedResourceChangeSet.new(resource).tap(&:prepopulate!)
    structure = document.structure
    members.each do |member|
      structure = structure.gsub(member.local_identifier[0], member.id.to_s)
    end

    thumbnail_id = find_thumbnail_id(members)
    @logger.warn "Failed to find the thumbnail ID for #{resource.id}" unless thumbnail_id

    change_set.validate(
      logical_structure: [logical_structure_from(structure)],
      thumbnail_id: thumbnail_id
    )
    change_set.sync
    change_set_persister.save(change_set: change_set)
  end

  def find_thumbnail_id(members)
    thumbnail_id = id_cache.fetch(document.thumbnail_id, Array.wrap(resource.thumbnail_id).first.to_s)
    return thumbnail_id if members.map(&:id).map(&:to_s).include?(thumbnail_id)
    members.find { |x| x.member_ids.map(&:to_s).include?(thumbnail_id) }.try(:id)
  end

  # A resource changeset
  def change_set
    @change_set ||= ScannedResourceChangeSet.new(resource).tap do |change_set|
      change_set.prepopulate!
      change_set.validate(change_set_attributes)
      change_set.sync
    end
  end

  def id_cache
    @id_cache ||= {}
  end

  def resource
    @resource ||= ScannedResource.new(document.attributes)
  end

  def derivative_storage_adapter
    Valkyrie::StorageAdapter.find(:plum_derivatives)
  end

  def derivative(member)
    PlumDerivative.new(member, document).file
  end

  def change_set_attributes
    {
      files: document.files,
      member_ids: document.members.map(&:id),
      visibility: document.visibility,
      local_identifier: document.id,
      pdf_type: document.pdf_type,
      rights_statement: document.rights_statement,
      member_of_collection_ids: document.collection_ids,
      viewing_hint: document.viewing_hint,
      viewing_direction: document.viewing_direction
    }
  end

  def plum_solr
    @plum_solr ||= RSolr.connect(url: Figgy.config["plum_solr_url"])
  end

  def plum_solr_get_document
    response = plum_solr.get("select", params: { q: "id:#{id}", rows: 1 })
    docs = response.dig("response", "docs") || []
    docs.first || {}
  end

  # the resource document
  def document
    @document ||= PlumDocument.new(plum_solr_get_document, self)
  end

  def all_collections
    @all_collections ||= query_service.find_all_of_model(model: Collection).group_by { |x| x.local_identifier.first }
  end

  class PlumDerivative
    attr_reader :file_set, :parent_document
    def initialize(file_set, parent_document)
      @file_set = file_set
      @parent_document = parent_document
    end

    def file
      IngestableFile.new(
        file_path: file_set_document.derivative_path,
        mime_type: "image/jp2",
        original_filename: "intermediate_file.jp2",
        use: [Valkyrie::Vocab::PCDMUse.ServiceFile],
        copyable: true
      )
    end

    def file_set_document
      @file_set_document ||= parent_document.file_set_documents.find { |x| x.id == file_set.local_identifier[0] }
    end
  end

  # resource document
  class PlumDocument
    attr_reader :solr_doc, :importer
    delegate :file_set_documents, to: :files_container
    def initialize(solr_doc, importer)
      @solr_doc = solr_doc
      @importer = importer
    end

    def attributes
      {
        depositor: solr_doc.fetch("depositor_ssim", []),
        source_metadata_identifier: solr_doc.fetch("source_metadata_identifier_ssim", []).first,
        title: solr_doc.fetch("title_tesim", []),
        state: solr_doc.fetch("workflow_state_name_ssim", []),
        identifier: solr_doc.fetch("identifier_tesim", []).first,
        local_identifier: solr_doc.fetch("local_identifier_ssim", []).first
      }
    end

    def id
      solr_doc['id']
    end

    def files
      @files ||= files_container.to_a
    end

    def files_container
      @files_container ||= Files.new(self)
    end

    def members
      @children ||= Children.new(self).to_a
    end

    def pdf_type
      solr_doc['pdf_type_ssim']
    end

    def thumbnail_id
      solr_doc.fetch("hasRelatedImage_ssim", []).first
    end

    def rights_statement
      solr_doc.fetch("rights_statement_tesim", []).first
    end

    def visibility
      if read_groups_value.blank?
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      elsif read_groups_value.include?(Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC)
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      else
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
    end

    def viewing_hint
      solr_doc.fetch("viewing_hint_ssim", []).first
    end

    def viewing_direction
      solr_doc.fetch("viewing_direction_ssim", []).first
    end

    def read_groups_value
      solr_doc["read_access_group_ssim"]
    end

    def collection_ids
      solr_doc.fetch("member_of_collection_ids_ssim", []).map do |id|
        find_or_create_collection(id).id
      end
    end

    def find_or_create_collection(id)
      Array.wrap(importer.all_collections.fetch(id) do
        CollectionImporter.new(id: id, change_set_persister: importer.change_set_persister).import!.tap do |collection|
          importer.all_collections[id] = collection
        end
      end).first
    end

    class CollectionImporter
      attr_reader :id, :change_set_persister
      def initialize(id:, change_set_persister:)
        @id = id
        @change_set_persister = change_set_persister
      end

      def import!
        change_set_persister.save(change_set: change_set)
      end

      def plum_solr
        @plum_solr ||= RSolr.connect(url: Figgy.config["plum_solr_url"])
      end

      def change_set
        @change_set ||= CollectionChangeSet.new(resource).tap do |change_set|
          change_set.prepopulate!
          change_set.validate(change_set_params)
          change_set.sync
        end
      end

      def change_set_params
        {
          slug: slug,
          title: title,
          description: description
        }
      end

      def resource
        @resource ||= Collection.new(local_identifier: id)
      end

      def slug
        document['exhibit_id_tesim'].first
      end

      def title
        document['title_tesim'].first
      end

      def description
        document.fetch('description_tesim', []).first
      end

      def document
        @document ||= plum_solr.get("select", params: {
                                      rows: 1,
                                      q: "id:#{id}",
                                      fq: "has_model_ssim:Collection"
                                    })["response"]["docs"].first
      end
    end

    class Children
      attr_reader :document
      delegate :importer, to: :document
      delegate :change_set_persister, to: :importer
      def initialize(document)
        @document = document
      end

      def to_a
        @to_a ||= child_documents.map do |id|
          child_importer = PlumImporter.new(id: id, change_set_persister: change_set_persister)
          output = child_importer.import!
          importer.id_cache = importer.id_cache.merge(child_importer.id_cache)
          output
        end
      end

      def child_documents
        @child_documents ||= raw_child_docs.map { |x| x['id'] }.sort_by { |x| ordered_ids.index(x) }
      end

      def raw_child_docs
        plum_solr.get("select", params: {
                        rows: 10_000,
                        q: "{!join from=ordered_targets_ssim to=id}id:\"#{document.id}/list_source\"",
                        fq: "has_model_ssim:ScannedResource",
                        fl: 'id'
                      })["response"]["docs"]
      end

      def ordered_ids
        @ordered_ids ||= plum_solr.get("select", params: { rows: 1, q: "id:\"#{document.id}/list_source\"" })["response"]["docs"].first.fetch("ordered_targets_ssim", [])
      end

      def plum_solr
        @plum_solr ||= RSolr.connect(url: Figgy.config["plum_solr_url"])
      end
    end

    class Files
      attr_reader :document
      def initialize(document)
        @document = document
      end

      def to_a
        file_set_documents.map do |file_set|
          IngestableFile.new(
            file_path: file_set.file_path,
            mime_type: "image/tiff",
            original_filename: file_set.original_filename,
            container_attributes: { local_identifier: file_set.id, title: file_set.title },
            node_attributes: file_set.file_attributes,
            copyable: true
          )
        end
      end

      def file_set_documents
        @file_set_documents ||= raw_file_set_docs.map { |x| FileSetDocument.new(x) }.sort_by { |x| ordered_ids.index(x.id) }
      end

      def raw_file_set_docs
        plum_solr.get("select", params: {
                        rows: 10_000,
                        q: "{!join from=ordered_targets_ssim to=id}id:\"#{document.id}/list_source\"",
                        fq: "has_model_ssim:FileSet"
                      })["response"]["docs"]
      end

      def ordered_ids
        @ordered_ids ||= plum_solr.get("select", params: { rows: 1, q: "id:\"#{document.id}/list_source\"" })["response"]["docs"].first.fetch("ordered_targets_ssim", [])
      end

      def plum_solr
        @plum_solr ||= RSolr.connect(url: Figgy.config["plum_solr_url"])
      end
    end

    # Provides the structural metadata cached in the Solr Document
    # @return [String]
    def structure
      values = solr_doc.fetch("logical_order_tesim", [])
      values.first || "{}"
    end
  end

  class FileSetDocument
    attr_reader :solr_doc
    def initialize(solr_doc)
      @solr_doc = solr_doc
    end

    def file_path
      PlumFilePath.new(self).binary
    end

    def derivative_path
      PlumFilePath.new(self).derivative
    end

    def original_filename
      solr_doc["label_tesim"].first
    end

    def id
      solr_doc["id"]
    end

    def title
      Array.wrap(solr_doc["title_tesim"]).first || original_filename
    end

    def file_attributes
      {
        width: solr_doc["width_is"].to_s,
        height: solr_doc["height_is"].to_s
      }
    end
  end

  class PlumFilePath
    attr_reader :file_set_document
    delegate :id, :original_filename, to: :file_set_document
    def initialize(file_set_document)
      @file_set_document = file_set_document
    end

    def binary
      plum_binary_path.join(*buckets).join(id).join(original_filename)
    end

    def derivative
      plum_derivative_path.join(*buckets).join("#{last_pair}-intermediate_file.jp2")
    end

    def last_pair
      id.chars.each_slice(2).map(&:join).last
    end

    def buckets
      id.chars.each_slice(2).map(&:join)[0..-2]
    end

    def plum_binary_path
      Pathname.new(Figgy.config["plum_binary_path"])
    end

    def plum_derivative_path
      Pathname.new(Figgy.config["plum_derivative_path"])
    end
  end
end
