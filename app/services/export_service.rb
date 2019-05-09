# frozen_string_literal: true
class ExportService
  def self.export(resource)
    export_members(resource.decorate)
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
    file = Valkyrie.config.storage_adapter.find_by(id: fileset.original_file.file_identifiers.first.id)
    FileUtils.mkdir_p("#{export_base}/#{prefix}")
    File.open(file_path(fileset, prefix), "w") { |dest| IO.copy_stream(file, dest) }
  end

  def self.file_path(fileset, prefix)
    "#{export_base}/#{prefix}/#{fileset.original_file.original_filename.first}"
  end

  def self.member_label(r)
    if r.respond_to?(:source_metadata_identifier) && !r.source_metadata_identifier.nil? && r.source_metadata_identifier.first.present?
      r.source_metadata_identifier.first
    else
      r.title.first
    end
  end
end
