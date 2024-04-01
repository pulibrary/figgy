# frozen_string_literal: true
class ExportService
  def self.export(resource)
    export_members(resource.decorate)
  end

  # Exports a PDF of a single-volume resource
  # @param resource [Resource] Resource to export
  # @param filename [String] Filename to export to, defaults to the resource ID with ".pdf" added
  def self.export_pdf(resource, filename: "#{resource.id}.pdf")
    fn = "#{export_base}/#{filename}"
    mtime = File.exist?(fn) && File.mtime(fn)
    Rails.logger.info("Skipping fresh PDF: #{fn}") && return if mtime && mtime > resource.updated_at

    pdf_desc = PDFService.new(change_set_persister).find_or_generate(resource_id: resource.id)
    file = Valkyrie.config.storage_adapter.find_by(id: pdf_desc.file_identifiers.first.id)
    FileUtils.mkdir_p(export_base)
    File.open(fn, "w") { |dest| IO.copy_stream(file, dest) }
  end

  # Exports a PDF of a single-volume resource, or PDFs for each volume of a multi-volume resource
  # @param resource [Resource] Resource to export
  # @param filename_base [String] Base filename, will have ".pdf" or "_0.pdf", etc. appended, defaults to the resource ID
  def self.export_resource_or_volumes_pdf(resource, filename_base: resource.id.to_s)
    if resource.decorate.volumes.empty?
      export_pdf(resource, filename: "#{filename_base}.pdf")
    else
      resource.decorate.volumes.each_with_index do |vol, index|
        export_pdf(vol, filename: "#{filename_base}_#{index}.pdf")
      end
    end
  end

  def self.change_set_persister
    @change_set_persister ||= ChangeSetPersister.new(
      metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
      storage_adapter: Valkyrie.config.storage_adapter
    )
  end

  def self.export_base
    Figgy.config["export_base"]
  end

  def self.export_members(r, prefix: nil)
    r.members.each do |member|
      if member.is_a?(FileSet)
        export_file(member, "#{prefix}/#{member_label(r)}")
      else
        export_members(member.decorate, prefix: "#{prefix}/#{member_label(r)}")
      end
    end
  end

  def self.export_file(fileset, prefix)
    file = Valkyrie.config.storage_adapter.find_by(id: fileset.primary_file.file_identifiers.first.id)
    FileUtils.mkdir_p("#{export_base}/#{prefix}")
    File.open(file_path(fileset, prefix), "w") { |dest| IO.copy_stream(file, dest) }
  end

  def self.file_path(fileset, prefix)
    "#{export_base}/#{prefix}/#{fileset.primary_file.original_filename.first}"
  end

  def self.member_label(r)
    if r.respond_to?(:source_metadata_identifier) && !r.source_metadata_identifier.nil? && r.source_metadata_identifier.first.present?
      r.source_metadata_identifier.first
    else
      r.title.first.tr("():;.", "").strip
    end
  end
end
