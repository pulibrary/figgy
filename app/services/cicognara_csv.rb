# frozen_string_literal: true
class CicognaraCSV
  def self.headers
    ["digital_cico_number", "label", "manifest", "contributing_library",
     "owner_call_number", "owner_system_number", "other_number",
     "version_edition_statement", "version_publication_statement", "version_publication_date",
     "additional_responsibility", "provenance", "physical_characteristics", "rights", "based_on_original"]
  end

  def self.values(col_id)
    col = Valkyrie.config.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(col_id))
    col.decorate.members.select { |r| extract_dclnum(r) && first(r.state) == "complete" }.map do |r|
      value(r.decorate)
    end
  end

  def self.value(r)
    dclnum = extract_dclnum(r)
    orig = original?(r)
    sysid = orig ? dclnum : first(r.source_metadata_identifier)
    label = orig ? "Microfiche" : "Princeton University Library"
    contrib = orig ? "Bibliotheca Apostolica Vaticana" : "Princeton University Library"

    [dclnum, label, Rails.application.routes.url_helpers.manifest_scanned_resource_url(r),
     contrib, first(r.imported_call_number), sysid, first(r.identifier), nil, first(r.imported_publisher),
     date(r), nil, nil, first(r.imported_extent), first(r.rights_statement).to_s, orig]
  end

  def self.first(value)
    Array.wrap(value).first
  end

  def self.date(r)
    Date.parse(first(r.imported_created)).strftime("%Y")
  rescue
    nil
  end

  def self.original?(r)
    first(r.rights_statement) == "http://cicognara.org/microfiche_copyright"
  end

  def self.extract_dclnum(r)
    local_identifier(r).find { |val| val.starts_with?("cico:") }
  end

  def self.local_identifier(r)
    (r.local_identifier || []) + (r.decorate.imported_local_identifier || [])
  end
end
