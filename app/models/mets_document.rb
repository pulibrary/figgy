# frozen_string_literal: true

# Class modeling METS Documents
# @see https://www.loc.gov/standards/mets/
class METSDocument
  include MetsStructure
  METS_XML_NAMESPACE = "http://www.loc.gov/METS/"

  attr_reader :source_file, :mets

  # @param [String] mets_file
  def initialize(mets_file)
    @source_file = mets_file
    @mets = File.open(@source_file) { |f| Nokogiri::XML(f) }
  end

  # Access the ARK ID
  # @return [String]
  def ark_id
    element = @mets.xpath("/mets:mets/@OBJID")
    element = element.to_s
    return nil unless element.include?("ark")
    element
  end

  # Access the bib. ID
  # @return [String]
  def bib_id
    element = @mets.xpath("/mets:mets/mets:dmdSec/mets:mdRef/@xlink:href")
    content = element.to_s
    content.gsub(/.*\//, "")
  end

  # Access the slug for the Collection
  # @return [String]
  def collection_slug
    element = @mets.xpath("/mets:mets/mets:structMap[@TYPE='RelatedObjects']//mets:div[@TYPE='IsPartOf']/@CONTENTIDS")
    element.to_s
  end

  # Access the ID for the PUDL resource
  # @return [String]
  def pudl_id
    elements = @mets.xpath("/mets:mets/mets:metsHdr/mets:metsDocumentID")
    element = elements.first
    content = element.content
    content.gsub(/\.mets/, "")
  end

  # Access the file path to the thumbnail image
  # @return [String]
  def thumbnail_path
    xp = "/mets:mets/mets:fileSec/mets:fileGrp[@USE='thumbnail']/mets:file/mets:FLocat/@xlink:href"
    element = @mets.xpath(xp)
    content = element.to_s
    content.gsub(/file:\/\//, "")
  end

  # Determine whether or not the resource described by the METS is
  #   right-to-left or left-to-right in viewing direction
  # @return [Boolean]
  def viewing_direction
    right_to_left ? "right-to-left" : "left-to-right"
  end

  # Determine whether or not the viewing direction for the described resource
  #   is right-to-left in viewing direction
  # @return [Boolean]
  def right_to_left
    element = @mets.xpath("/mets:mets/mets:structMap[@TYPE='Physical']/mets:div/@TYPE")
    content = element.to_s
    content.start_with? "RTL"
  end

  # Access the viewing hint encoded in the METS Document
  # @return [String]
  def viewing_hint
    attribute = @mets.xpath("/mets:mets/mets:structMap[@TYPE='Physical']/mets:div/@TYPE")
    type = attribute.to_s
    return if ["TightBoundManuscript", "ScrollSet", "BoundArt"].any? { |w| type.include?(w) }
    "paged"
  end

  # Determine if the described resource is a multi-volume work
  # @return [Boolean]
  def multi_volume?
    volume_nodes.length > 1
  end

  # Retrieve the IDs for the volumes encoded in the METS Document
  # @return [Array<String>]
  def volume_ids
    volume_nodes.map do |vol|
      vol.attribute("ID").value
    end
  end

  # Provide the label for the described resource
  # (This defaults to an empty array)
  # @return [Array]
  def label
    []
  end

  # For a given volume ID, retrieve the label for that volume
  # @param [String] volume_id ID for the volume
  # @return [String]
  def label_for_volume(volume_id)
    volume_node = volume_nodes.find { |vol| vol.attribute("ID").value == volume_id }
    return volume_node.attribute("LABEL").value if volume_node
  end

  # For a given volume ID, retrieve the information for each file associated
  #   with the volume
  # @param [String] volume_id ID for the volume
  # @return [Array<Hash>]
  def files_for_volume(volume_id)
    @mets.xpath("//mets:div[@ID='#{volume_id}']//mets:fptr/@FILEID").map(&:value).uniq.map do |file_id|
      file_info(@mets.xpath("//mets:file[@ID='#{file_id}']"), volume_id)
    end
  end

  # Retrieve all information for files encoded in the METS
  # @return [Hash<Array>]
  def files
    @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp[@USE='masters']/mets:file").map do |f|
      file_info(f)
    end
  end

  # For a given XML element encoding a file description (and an optional ID for
  #   a volume), construct a Hash containing information about the file
  # @param [Nokogiri::XML::Node] file the file XML element
  # @param [String] volume_id the ID for the volume
  # @return [Hash]
  def file_info(file, volume_id = nil)
    element = file.xpath("mets:FLocat/@xlink:href")
    content = element.to_s
    path = content.gsub(/file:\/\//, "")
    replaces = volume_id ? "#{volume_id}/" : ""
    replaces += File.basename(path, File.extname(path))
    {
      id: file.xpath("@ID").to_s,
      checksum: file.xpath("@CHECKSUM").to_s.rjust(40, "0"),
      mime_type: file.xpath("@MIMETYPE").to_s,
      path: path,
      replaces: "#{pudl_id}/#{replaces}"
    }
  end

  # Retrieve options relating to the encoded file
  # @param [Nokogiri::XML::Node] file the file XML element
  # @return [Hash]
  def file_opts(file)
    return {} if @mets.xpath("count(//mets:div/mets:fptr[@FILEID='#{file[:id]}'])").positive?
    {viewing_hint: "non-paged"}
  end

  # Construct an IngestableFile object given a Hash containing file attributes
  # @param [Hash] f file attributes
  # @return [IngestableFile]
  def decorated_file(f)
    IngestableFile.new(
      file_path: f[:path],
      mime_type: f[:mime_type],
      original_filename: File.basename(f[:path]),
      container_attributes: container_attributes(f),
      id: f[:id],
      copyable: true
    )
  end

  # Generate the attributes for the container resource given a Hash of file
  #   attributes
  # @param [Hash] file file attributes
  # @param [Hash]
  def container_attributes(file)
    {
      title: file_label(file[:id])
    }
  end

  # Construct the MODS Document object using the METS XML Document and an XPath
  # @return [MODSDocument]
  def mods
    @mods ||= MODSDocument.from(mets: @mets, xpath: "/mets:mets/mets:dmdSec/mets:mdWrap/mets:xmlData/mods:mods")
  end

  # Generate the metadata attributes for the resource being described
  # @return [Hash]
  def attributes
    return {} if mods.nil?
    {
      title: mods.title,
      sort_title: mods.sort_title,
      alternative_title: mods.alternative_title,
      uniform_title: mods.uniform_title,
      archival_collection_code: mods.collection_code,
      date_created: mods.date_created,
      date_issued: mods.date_issued,
      date_copyright: mods.date_copyright,
      date_published: mods.date_published,
      extent: mods.extent,
      resource_type: mods.type_of_resource,
      subject: mods.subject,
      description: mods.note,
      abstract: mods.abstract,
      contents: mods.table_of_contents,
      rights_statement: map_to_rights_statement(mods.access_condition),
      genre: mods.genre,
      holding_location: map_to_holding_location(mods.holding_simple_sublocation),
      location: mods.shelf_locator,
      creator: mods.creator,
      geographic_origin: mods.geographic_origin,
      language: mods.language,
      series: mods.series,
      part_of: mods.finding_aid_identifier,
      replaces: mods.replaces,
      photographer: mods.photographer,
      local_identifier: mods.local_identifier,
      actor: mods.actor,
      director: mods.director,
      coverage_point: mods.coverage_point,
      publisher: mods.publisher
    }
  end
  # rubocop:enable Metrics/AbcSize

  private

    # currently this just returns the default, but can be adjusted to do actual mapping as needed
    def map_to_rights_statement(_access_condition)
      RightsStatements.copyright_not_evaluated.to_s
    end

    def map_to_holding_location(locations)
      return unless locations.present?
      ControlledVocabulary.for(:holding_location).all.find { |term| term.label.include? locations.first }&.value
    end

    # Access the XML elements encoding information about volumes in the METS
    #   Document
    # @return [Nokogiri::XML::NodeSet]
    def volume_nodes
      xp = "/mets:mets/mets:structMap[@TYPE='Physical']/mets:div[@TYPE='MultiVolumeSet']/mets:div"
      @volume_nodes ||= logical_volumes || @mets.xpath(xp)
    end

    # Access the XML elements encoding information about volumes in the METS
    #   Document if they are encoded as a logical structural map (structMap)
    # @return [Nokogiri::XML::NodeSet]
    def logical_volumes
      xp = "/mets:mets/mets:structMap[@TYPE='Logical']/mets:div/mets:div[starts-with(@TYPE, 'Bound')]"
      log = @mets.xpath(xp)
      log if log && !log.empty?
    end
end
