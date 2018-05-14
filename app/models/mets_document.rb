# frozen_string_literal: true
class METSDocument
  include MetsStructure
  attr_reader :source_file, :mets

  def initialize(mets_file)
    @source_file = mets_file
    @mets = File.open(@source_file) { |f| Nokogiri::XML(f) }
  end

  def ark_id
    @mets.xpath("/mets:mets/@OBJID").to_s
  end

  def bib_id
    @mets.xpath("/mets:mets/mets:dmdSec/mets:mdRef/@xlink:href").to_s.gsub(/.*\//, "")
  end

  def collection_slug
    @mets.xpath("/mets:mets/mets:structMap[@TYPE='RelatedObjects']//mets:div[@TYPE='IsPartOf']/@CONTENTIDS").to_s
  end

  def pudl_id
    @mets.xpath("/mets:mets/mets:metsHdr/mets:metsDocumentID").first.content.gsub(/\.mets/, "")
  end

  def thumbnail_path
    xp = "/mets:mets/mets:fileSec/mets:fileGrp[@USE='thumbnail']/mets:file/mets:FLocat/@xlink:href"
    @mets.xpath(xp).to_s.gsub(/file:\/\//, "")
  end

  def viewing_direction
    right_to_left ? "right-to-left" : "left-to-right"
  end

  def right_to_left
    @mets.xpath("/mets:mets/mets:structMap[@TYPE='Physical']/mets:div/@TYPE").to_s.start_with? "RTL"
  end

  def viewing_hint
    type = @mets.xpath("/mets:mets/mets:structMap[@TYPE='Physical']/mets:div/@TYPE").to_s
    return if ["TightBoundManuscript", "ScrollSet", "BoundArt"].any? { |w| type.include?(w) }
    "paged"
  end

  def multi_volume?
    volume_nodes.length > 1
  end

  def volume_ids
    volume_nodes.map do |vol|
      vol.attribute("ID").value
    end
  end

  def label
    []
  end

  def label_for_volume(volume_id)
    volume_node = volume_nodes.find { |vol| vol.attribute("ID").value == volume_id }
    return volume_node.attribute("LABEL").value if volume_node
  end

  def files_for_volume(volume_id)
    @mets.xpath("//mets:div[@ID='#{volume_id}']//mets:fptr/@FILEID").map(&:value).uniq.map do |file_id|
      file_info(@mets.xpath("//mets:file[@ID='#{file_id}']"), volume_id)
    end
  end

  def files
    @mets.xpath("/mets:mets/mets:fileSec/mets:fileGrp[@USE='masters']/mets:file").map do |f|
      file_info(f)
    end
  end

  def file_info(file, volume_id = nil)
    path = file.xpath("mets:FLocat/@xlink:href").to_s.gsub(/file:\/\//, "")
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

  def file_opts(file)
    return {} if @mets.xpath("count(//mets:div/mets:fptr[@FILEID='#{file[:id]}'])").positive?
    { viewing_hint: "non-paged" }
  end

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

  def container_attributes(file)
    {
      title: file_label(file[:id])
    }
  end

  private

    def volume_nodes
      xp = "/mets:mets/mets:structMap[@TYPE='Physical']/mets:div[@TYPE='MultiVolumeSet']/mets:div"
      @volume_nodes ||= logical_volumes || @mets.xpath(xp)
    end

    def logical_volumes
      xp = "/mets:mets/mets:structMap[@TYPE='Logical']/mets:div/mets:div[starts-with(@TYPE, 'Bound')]"
      log = @mets.xpath(xp)
      log if log && !log.empty?
    end
end
