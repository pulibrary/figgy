# frozen_string_literal: true
# get all the data files, provide lookups based on component and barcode
class ArchivalMediaBagParser
  BARCODE_WITH_SIDE_REGEX = /(\d{14}_\d+)_.*/.freeze
  BARCODE_WITH_SIDE_AND_PART_REGEX = /(\d{14}_\d+?_p\d+).*/.freeze
  attr_reader :path, :component_dict

  def initialize(path:, component_id:, barcodes: nil)
    @path = path
    @component_dict = BarcodeComponentDict.new(component_id)
    @barcodes = barcodes
  end

  # Constructs IngestableAudioFile objects for each wav/mp3 file in the Bag
  # @return [Array<IngestableAudioFile>]
  def audio_files
    @audio_files ||= path.join("data").each_child.select { |file| [".wav", ".mp3"].include? file.extname }.map { |file| IngestableAudioFile.new(path: file) }
  end

  def barcodes
    @barcodes ||= audio_files.map(&:barcode).uniq
  end

  def audio_files_by_barcode
    @audio_files_by_barcode ||= audio_files.group_by(&:barcode)
  end

  def audio_files_for_barcode(barcode:)
    audio_files_by_barcode[barcode].group_by(&:barcode_with_side_and_part)
  end

  # file in groups by component id
  # @return [Hash] map keying EAD component IDs to array of barcodes
  #   Array is ordered by location of barcodes in EAD
  def component_groups
    @component_groups ||=
      begin
        h = {}
        barcodes.each do |barcode|
          cid = component_dict.component_id(barcode: barcode)
          h[cid] = h.fetch(cid, []).append(barcode).uniq
        end
        h.each do |component_id, barcodes|
          h[component_id] = barcodes.sort_by do |barcode|
            component_dict.barcodes(cid: component_id)&.index(barcode)
          end
        end
        h
      end
  end

  def pbcore_parser(barcode:)
    pbcore_parsers.find { |pbcore| pbcore.barcode == barcode }
  end

  def image_file(barcode:)
    image_files.find { |image| image.barcode == barcode }
  end

  # Validates that this is in compliance with the BagIt specification
  # @see https://tools.ietf.org/html/draft-kunze-bagit-14 BagIt File Packaging Format
  # @return [TrueClass, FalseClass]
  def valid?
    bag = BagIt::Bag.new @path
    bag.valid?
  end

  # Class modeling asset images
  class ImageFile
    attr_reader :path

    # Provide the MIME type used for all image files
    # @return [String]
    def self.mime_type
      "image/jpeg"
    end

    # Constructor
    # @param path [Pathname] path to the image file
    def initialize(path:)
      @path = path
    end

    # Retrieve the original filename
    def original_filename
      @original_filename ||= path.basename.to_s
    end

    # Retrieve the barcode
    def barcode
      @barcode ||= path.basename.to_s.split("_").first
    end

    # Generate the MIME type
    # @return [String]
    def mime_type
      self.class.mime_type
    end
  end

  private

    # pbcore parsers by barcode
    # @return [Array] of PbcoreParser objects
    def pbcore_parsers
      @pbcore_parsers ||=
        begin
          path.join("data").each_child.select { |file| [".xml"].include? file.extname }.map { |file| PbcoreParser.new(path: file) }
        end
    end

    # Retrieve the JPEGs for the assets
    # @return [Array<Image>]
    def image_files
      @image_files ||=
        begin
          path.join("data").each_child.select { |file| [".jpg"].include? file.extname.downcase }.map { |file| ImageFile.new(path: file) }
        end
    end
end

# A couple of hashes
# look up a barcode, get a component id
# look up a component id, get all its barcodes in order
class BarcodeComponentDict
  attr_reader :cid_lookup, :barcode_lookup
  # Constructor
  # @param component_id [String]
  def initialize(component_id)
    @component_id = component_id
    parse_cid_lookup
    parse_barcode_lookup
  end

  def barcodes(cid:)
    barcode_lookup[cid]
  end

  # Retrieve an EAD component ID for any given barcode
  # @param barcode [String] the barcode
  # @param [String] the EAD component ID
  def component_id(barcode:)
    @cid_lookup[barcode]
  end

  private

    # query the EAD for filenames, navigates back up to their component IDs
    def parse_cid_lookup
      @cid_lookup = {}
      barcode_nodes.each do |node|
        barcode = get_barcode(node)
        @cid_lookup[barcode] = get_id(node) unless barcode.nil?
      end
    end

    def parse_barcode_lookup
      @barcode_lookup = {}
      id_nodes.each do |node|
        @barcode_lookup[node.attributes["id"].value] = node_barcodes(node)
      end
    end

    def node_barcodes(node)
      node.xpath("altformavail/p").map { |barcode_node| get_barcode(barcode_node) }.uniq
    end

    def remote_record_source_metadata
      @remote_record_source_metadata ||= PulMetadataServices::Client.retrieve_aspace_pulfa_ead(@component_id)
    end

    # Parses XML from Collection Resource metadata
    # @return [Nokogiri::XML::Element] the root element of the XML Document
    def xml
      @xml ||= Nokogiri::XML(remote_record_source_metadata).remove_namespaces!
    end

    # Retrieves the set of XML Elements containing barcodes within the EAD
    # @return [Nokogiri::XML::Set]
    def barcode_nodes
      xml.xpath("//altformavail/p")
    end

    def id_nodes
      xml.xpath("//altformavail/parent::c")
    end

    # Retrieves a "grandparent" ID attribute value for any given  XML Element
    # @param node [Nokogiri::XML::Node]
    # @return [String]
    def get_id(node)
      node.parent.parent.attributes["id"].value
    end

    # Extracts the barcode using the XML Element content and a regexp
    # @param node [Nokogiri::XML::Node]
    # @return [String, nil] the captured string content
    def get_barcode(node)
      node.content.split("_").first.strip
    end
end

class PbcoreParser
  attr_reader :path
  def initialize(path:)
    @path = path
  end

  def mime_type
    "application/xml; schema=pbcore"
  end

  def original_filename
    @original_filename ||= path.basename.to_s
  end

  def main_title
    @main_title ||= xml.xpath("//pbcoreTitle").first.text
  end

  def barcode
    @barcode ||= path.basename(".xml").to_s
  end

  def transfer_notes
    @transfer_notes ||= xml.xpath('//instantiationAnnotation[@annotationType="Transfer Comments"]').first.text
  end

  # Parses XML from the pbcore file
  # @return [Nokogiri::XML::Element] the root element of the XML Document
  def xml
    @xml ||= Nokogiri::XML(path).remove_namespaces!
  end
end
