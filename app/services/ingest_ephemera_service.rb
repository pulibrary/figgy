# frozen_string_literal: true

class IngestEphemeraService
  delegate :metadata_adapter, to: :change_set_persister
  delegate :query_service, to: :metadata_adapter
  attr_reader :folder_dir, :state, :project, :logger, :change_set_persister
  def initialize(folder_dir, state, project, change_set_persister, logger = Logger.new($stdout))
    @folder_dir = folder_dir
    @state = state
    @project = project
    @change_set_persister = change_set_persister
    @logger = logger
  end

  def ingest
    box = find_or_create_box
    change_set.validate(desc_metadata.attributes)
    change_set.validate(prov_metadata.attributes)
    change_set.validate(default_attributes)
    change_set.validate(state: state) if state
    change_set.validate(append_id: box.id)
    change_set_persister.save(change_set: change_set)
  rescue => e
    logger.warn "Error: #{e.message}"
    logger.warn e.backtrace.join("\n")
  end

  def find_or_create_box
    box = find_box(box_metadata.box_id)
    return box if box
    box = EphemeraBox.new(local_identifier: box_metadata.box_id)
    change_set = EphemeraBoxChangeSet.new(box)
    change_set.validate(box_prov_metadata(box).attributes)
    change_set.validate(append_id: project_resource.id)
    change_set_persister.save(change_set: change_set)
  end

  def project_resource
    @project_resource ||= query_service.custom_queries.find_by_property(property: :title, value: project).first
  end

  def find_box(id)
    query_service.custom_queries.find_by_local_identifier(local_identifier: id).first
  end

  def basedir
    File.expand_path("../..", folder_dir)
  end

  def box_prov_metadata(box)
    ProvMetadata.new(File.open("#{basedir}/boxes/#{box.local_identifier.first}/provMetadata"), box)
  end

  def box_metadata
    @box_metadata ||= BoxMetadata.new(foxml_file)
  end

  def foxml_file
    File.open("#{folder_dir}/foxml") { |f| Nokogiri::XML(f) }
  end

  class BoxMetadata
    attr_reader :foxml_file
    def initialize(foxml_file)
      @foxml_file = foxml_file
    end

    def box_id
      @box_id ||= foxml_file.xpath("//pulstore:inBox/@rdf:resource", namespaces).first.value.gsub(/.*:/, "")
    end

    def namespaces
      {
        pulstore: "http://princeton.edu/pulstore/terms/",
        rdf: "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      }
    end
  end

  def default_attributes
    {
      pdf_type: "none",
      rights_statement: RightsStatements.copyright_not_evaluated.to_s,
      files: files,
      local_identifier: local_identifier
    }
  end

  def local_identifier
    File.basename(folder_dir)
  end

  def resource
    @resource ||= EphemeraFolder.new
  end

  def change_set
    @change_set ||= EphemeraFolderChangeSet.new(resource)
  end

  def prov_metadata
    ProvMetadata.new(prov_file, resource)
  end

  def desc_metadata
    DescMetadata.new(desc_file, query_service)
  end

  def prov_file
    @prov_file ||= File.open("#{folder_dir}/provMetadata")
  end

  def desc_file
    @desc_file ||= File.open("#{folder_dir}/descMetadata")
  end

  def files
    FolderPageCollection.new(folder_dir).to_a
  end

  class FolderPageCollection
    attr_reader :folder_dir

    def initialize(folder_dir)
      @folder_dir = folder_dir
    end

    def to_a
      page_identifiers.map do |identifier|
        Page.new(self, identifier)
      end
    end

    def page_folder_hash
      @page_folder_hash ||= read_hash("#{basedir}/pagefolders.txt")
    end

    def page_identifiers
      page_folder_hash.fetch(File.basename(folder_dir), []).sort
    end

    def read_hash(filename)
      h = {}
      File.open(filename).each do |line|
        val, key = line.split(" ")
        h[key] = (h[key] || []).push(val)
      end

      h
    end

    def basedir
      File.expand_path("../..", folder_dir)
    end

    class Page
      attr_reader :folder_page_collection, :page_id
      delegate :basedir, :folder_dir, :read_hash, to: :folder_page_collection
      def initialize(folder_page_collection, page_id)
        @folder_page_collection = folder_page_collection
        @page_id = page_id
      end

      def page_number
        graph.query([nil, ::PULStore.sortOrder, nil]).first.object.to_s
      end

      def graph
        @graph ||= RDF::Graph.load("#{basedir}/pages/#{page_id[0..1]}/#{page_id}/descMetadata")
      end

      def master_image_hash
        @master_image_hash ||= read_hash("#{basedir}/masterImage.txt")
      end

      # Methods necessary for FileAppender

      def path
        @path ||= "#{basedir}/#{master_image_hash[page_id].first}"
      end

      def content_type
        "image/tiff"
      end

      def original_filename
        "master_image.tif"
      end

      def container_attributes
        {
          title: page_number
        }
      end

      def use
        nil
      end
    end
  end

  class ProvMetadata
    attr_reader :file, :resource
    def initialize(file, resource)
      @file = file
      @resource = resource
    end

    def attributes
      {
        barcode: barcode,
        folder_number: folder_number,
        box_number: box_number,
        visibility: visibility,
        tracking_number: tracking_number,
        shipped_date: shipped_date,
        received_date: received_date,
        state: state
      }
    end

    def barcode
      value(::PULStore.barcode)
    end

    def folder_number
      return unless resource.is_a?(EphemeraFolder)
      physical_number
    end

    def box_number
      return unless resource.is_a?(EphemeraBox)
      physical_number
    end

    def physical_number
      value(::PULStore.physicalNumber)
    end

    def visibility
      return visibility_private if suppressed?
      visibility_public
    end

    def suppressed?
      value(::PULStore.suppressed) == ["true"]
    end

    def visibility_public
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def visibility_private
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end

    def tracking_number
      value(::PULStore.trackingNumber)
    end

    def shipped_date
      value(::PULStore.shippedDate)
    end

    def received_date
      value(::PULStore.receivedDate)
    end

    def state
      val = value(::PULStore.state).first.downcase.tr(" ", "_")
      resource.is_a?(EphemeraBox) ? box_state(val) : folder_state(val)
    end

    def box_state(val)
      box_workflow.valid_states.include?(val) ? val : box_workflow.aasm.current_state.to_s
    end

    def box_workflow
      @box_workflow ||= BoxWorkflow.new(nil)
    end

    def folder_state(val)
      val.eql?("in_production") ? "complete" : FolderWorkflow.new(nil).aasm.current_state.to_s
    end

    def value(predicate)
      stmt = graph.query([nil, predicate, nil]).first
      [stmt.object.to_s] if stmt && stmt.object.to_s
    end

    def graph
      @graph ||= RDF::Graph.load(file.path)
    end
  end

  class DescMetadata
    attr_reader :file, :query_service
    def initialize(file, query_service)
      @file = file
      @query_service = query_service
    end

    def attributes
      {
        title: title,
        alternative_title: alternative_title,
        series: series,
        description: description,
        publisher: publisher,
        creator: creator,
        contributor: contributor,
        date_created: date_created,
        genre: genre,
        subject: subject,
        language: language,
        geo_subject: geo_subject,
        geographic_origin: geographic_origin,
        sort_title: sort_title,
        date_range: date_range,
        height: height,
        width: width,
        page_count: page_count
      }
    end
    # rubocop:enable Metrics/MethodLength

    def date_range
      return unless date_start && date_end
      DateRange.new(start: date_start, end: date_end)
    end

    def height
      value(::PULStore.heightInCM)
    end

    def width
      value(::PULStore.widthInCM)
    end

    def page_count
      value(::PULStore.pageCount)
    end

    def date_start
      value(::PULStore.earliestCreated)
    end

    def date_end
      value(::PULStore.latestCreated)
    end

    def title
      value(::RDF::Vocab::DC.title)
    end

    def sort_title
      value(::PULStore.sortTitle)
    end

    def series
      value(::PULStore.isPartOfSeries)
    end

    def alternative_title
      value(::RDF::Vocab::DC.alternative)
    end

    def description
      value(::RDF::Vocab::DC.description)
    end

    def publisher
      value(::RDF::Vocab::DC.publisher)
    end

    def creator
      value(::RDF::Vocab::DC.creator)
    end

    def contributor
      value(::RDF::Vocab::DC.contributor)
    end

    def date_created
      value(::RDF::Vocab::DC.created)
    end

    def genre
      value(::RDF::Vocab::DC.format).map do |value|
        find_term(value, "LAE Genres")
      end.first
    end

    def subject
      value(::RDF::Vocab::DC.subject).map do |value|
        find_term(value, nil)
      end
    end

    def language
      value(::RDF::Vocab::DC.language).map do |value|
        find_term(value, "LAE Languages")
      end
    end

    def geo_subject
      value(::RDF::Vocab::DC.coverage).map do |value|
        find_term(value, "LAE Areas")
      end
    end

    def geographic_origin
      value(::RDF::Vocab::MARCRelators.mfp).map do |value|
        find_term(value, "LAE Areas")
      end
    end

    def find_term(label, vocab_label)
      query_service.custom_queries.find_ephemera_term_by_label(label: label, parent_vocab_label: vocab_label).id
    rescue
      label
    end

    def value(predicate)
      graph.query([nil, predicate, nil]).map(&:object).map(&:to_s).select(&:present?)
    end

    def graph
      @graph ||= RDF::Graph.load(file.path)
    end
  end
end
