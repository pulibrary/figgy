# frozen_string_literal: true
class CicognaraCSV
  def self.headers
    ['digital_cico_number', 'label', 'manifest', 'contributing_library',
     'owner_call_number', 'owner_system_number', 'other_number',
     'version_edition_statement', 'version_publication_statement', 'version_publication_date',
     'additional_responsibility', 'provenance', 'physical_characteristics', 'rights', 'based_on_original']
  end

  def self.values(col_id)
    col = Valkyrie.config.metadata_adapter.query_service.find_by(id: Valkyrie::ID.new(col_id))
    col.decorate.members.map(&:decorate).map do |r|
      value(r) if extract_dclnum(r) && r.state.first == "complete"
    end
  end

  def self.value(r)
    [extract_dclnum(r), label(r), Rails.application.routes.url_helpers.manifest_scanned_resource_url(r),
     "Princeton University Library", r.imported_call_number.first, r.source_metadata_identifier.first,
     r.identifier.first, nil, r.imported_publisher.first, date(r), nil, nil, r.imported_extent.first,
     r.rights_statement.first.to_s, original?(r)]
  end

  def self.date(r)
    Date.parse(r.imported_created.first).strftime("%Y")
  rescue
    nil
  end

  def self.label(r)
    return "Microfiche" if original?(r)
    "Princeton University Library"
  end

  def self.original?(r)
    r.rights_statement.first == 'http://cicognara.org/microfiche_copyright'
  end

  def self.extract_dclnum(r)
    local_identifier(r).select { |val| val.starts_with?("cico:") }.first
  end

  def self.local_identifier(r)
    (r.local_identifier || []) + (r.decorate.imported_local_identifier || [])
  end
end
