# frozen_string_literal: true
# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end
ActiveSupport::Inflector.inflections(:en) do |inflect|
  # Acronyms added to fix class loading with zeitwerk.
  # We might want to replace some (all) of these, but replacing CDL will require a
  # data migration because CDL::Resource is stored in the change_set column.
  inflect.acronym "OCR"
  inflect.acronym "PDF"
  inflect.acronym "CDL"
  inflect.acronym "IIIF"
  inflect.acronym "MARC"
  inflect.acronym "VIPS"
  inflect.acronym "JP2"
  inflect.acronym "CSV"
  inflect.acronym "MODS"
  inflect.acronym "METS"
end
# These map file names to constants for cases where they don't match the above
# acronyms. Remove when we fix the above.
acronyms = {
  "blacklight_iiif_search" => "BlacklightIiifSearch",
  "create_ocr_request_job" => "CreateOcrRequestJob",
  "pdf_ocr_job" => "PdfOcrJob",
  "reprocess_mets_job" => "ReprocessMetsJob",
  "iiif_search_builder" => "IiifSearchBuilder",
  "mets_structure" => "MetsStructure",
  "ocr_request" => "OcrRequest",
  "pudl3_mvw_mets_document" => "Pudl3MVWMetsDocument",
  "labeled_uri" => "LabeledURI",
  "cicognara_marc" => "CicognaraMarc",
  "folder_json_importer" => "FolderJSONImporter",
  "marc_record_enhancer" => "MarcRecordEnhancer",
  "pul_store" => "PULStore",
  "cdl_controller" => "CdlController",
  "iiif_search" => "IiifSearch",
  "iiif_search_annotation" => "IiifSearchAnnotation",
  "iiif_search_response" => "IiifSearchResponse",
  "iiif_suggest_response" => "IiifSuggestResponse",
  "iiif_suggest_search" => "IiifSuggestSearch",
  "oai" => "OAI",
  "marc21" => "MARC21",
  "oai_wrapper" => "OAIWrapper"
}

Rails.autoloaders.main.inflector.inflect(acronyms)
