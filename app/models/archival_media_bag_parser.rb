# frozen_string_literal: true
# get all the data files, provide lookups based on component and barcode
class ArchivalMediaBagParser
  BARCODE_WITH_PART_REGEX = /(\d{14}_\d+)_.*/
  attr_reader :path, :audio_files, :file_groups, :component_groups, :component_dict, :pbcore_parsers

  def initialize(path:, component_id:)
    @path = path
    @component_dict = BarcodeComponentDict.new(component_id)
  end

  # group all the files in the bag by barcode_with_part
  # @return [Hash] mapping string barcode_with_part to an array of IngestableAudioFiles
  def file_groups
    @file_groups ||= audio_files.group_by(&:barcode_with_part)
  end

  # file_groups in groups by component id
  # @return [Hash] map keying EAD component IDs to file barcodes (with part qualifier, e.g. "32101047382401_1")
  def component_groups
    @component_groups ||=
      begin
        h = {}
        file_groups.keys.each do |barcode_with_part|
          cid = component_dict.lookup(barcode_with_part)
          h[cid] = h.fetch(cid, []).append(barcode_with_part)
        end
        h
      end
  end

  def pbcore_parser_for_barcode(barcode)
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

  private

    # Class modeling asset images
    class ImageFile
      attr_reader :path, :original_filename, :barcode

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

    # pbcore parsers by barcode
    # @return [Array] of PbcoreParser objects
    def pbcore_parsers
      @pbcore_parsers ||=
        begin
          path.join("data").each_child.select { |file| [".xml"].include? file.extname }.map { |file| PbcoreParser.new(path: file) }
        end
    end

    # Constructs IngestableAudioFile objects for each wav/mp3 file in the Bag
    # @return [Array<IngestableAudioFile>]
    def audio_files
      @audio_files ||= path.join("data").each_child.select { |file| [".wav", ".mp3"].include? file.extname }.map { |file| IngestableAudioFile.new(path: file) }
    end

    # Retrieve the JPEGs for the assets
    # @return [Array<Image>]
    def image_files
      @image_files ||=
        begin
          path.join("data").each_child.select { |file| [".jpg"].include? file.extname }.map { |file| ImageFile.new(path: file) }
        end
    end
end

# Dictionary implemented using a wrapper for a Hash
# Wraps a hash of component_id => barcode_with_part
class BarcodeComponentDict
  attr_reader :dict
  # Constructor
  # @param collection [ArchivalMediaCollection]
  def initialize(component_id)
    @component_id = component_id
    parse_dict!
  end

  # Retrieve an EAD component ID for any given barcode
  # @param barcode_with_part [String] the barcode
  # @param [String] the EAD component ID
  def lookup(barcode_with_part)
    @dict[barcode_with_part]
  end

  private

    # query the EAD for filenames, navigates back up to their component IDs
    def parse_dict!
      @dict = {}
      barcode_nodes.each do |node|
        barcode = get_barcode_with_part(node)
        @dict[barcode] = get_id(node) unless barcode.nil?
      end
    end

    # Parses XML from Collection Resource metadata
    # @return [Nokogiri::XML::Element] the root element of the XML Document
    def xml
      @xml ||= Nokogiri::XML(RemoteRecord.retrieve(@component_id).attributes[:source_metadata]).remove_namespaces!
    end

    # Retrieves the set of XML Elements containing barcodes within the EAD
    # @return [Nokogiri::XML::Set]
    def barcode_nodes
      xml.xpath("//altformavail/p")
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
    def get_barcode_with_part(node)
      match = ArchivalMediaBagParser::BARCODE_WITH_PART_REGEX.match(node.content)
      return if match.nil?
      match[1]
    end
end

class PbcoreParser
  attr_reader :path, :barcode, :transfer_notes, :xml, :original_filename
  def initialize(path:)
    @path = path
  end

  def original_filename
    @original_filename ||= path.basename.to_s
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
