# frozen_string_literal: true

class CicognaraMarc
  attr_reader :collection_id
  attr_accessor :out_dir

  def initialize(cico_collection_id:, out_dir: Rails.root.join("tmp", "cicognara_marc_output"))
    @collection_id = cico_collection_id
    @out_dir = out_dir
  end

  def run
    collection = query_service.find_by(id: collection_id)
    wayfinder = Wayfinder.for(collection)
    wayfinder
      .members
      .select { |member| visible?(member) && readable_state?(member) }
      .group_by(&:source_metadata_identifier)
      .values
      .map { |group| retrieve_ehanced_marc(group) }
      .compact
      .each { |record| write_marc_record(record) }
  end

  def retrieve_ehanced_marc(arr)
    arr
      .map { |r| MarcRecordEnhancer.for(r)&.enhance_cicognara }
      .reduce do |init, record|
        ["856", "024", "510"].each do |field|
          # can't use uniq because that compares object ID; include? uses `==`
          all_vals = init.fields(field).tap do |vals|
            record.fields(field).each do |potential_val|
              vals << potential_val unless init.fields(field).include? potential_val
            end
          end
          init.fields(field).to_a.each { |f| init.fields.delete(f) }
          all_vals.each { |val| init.append val }
        end
        init
      end
  end

  private

    def visible?(member)
      member.visibility.first == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def readable_state?(member)
      member.decorate.public_readable_state?
    end

    def write_marc_record(record)
      bib_number = record["001"].value
      writer = MARC::XMLWriter.new(File.join(out_dir, "#{bib_number}_marc.xml"))
      writer.write(record)
    end

    def query_service
      Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    end
end
