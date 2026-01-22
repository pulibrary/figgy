class CicognaraMarc
  attr_reader :collection_id
  attr_accessor :out_dir

  def initialize(cico_collection_id:, out_dir: Rails.root.join("tmp", "cicognara_marc_output"))
    @collection_id = cico_collection_id
    @out_dir = out_dir
  end

  def run
    marc_records.each { |record| write_marc_record(record) }
  end

  def retrieve_ehanced_marc(arr)
    arr
      .map { |r| MarcRecordEnhancer.for(r)&.enhance_cicognara }
      .reduce { |init, record| combine_records(init, record) }
  end

  private

    def marc_records
      publishable_resource_groups.map { |group| retrieve_ehanced_marc(group) }.compact
    end

    def publishable_resource_groups
      publishable_resources.group_by(&:source_metadata_identifier).values
    end

    def publishable_resources
      wayfinder.members.select { |member| visible?(member) && readable_state?(member) }
    end

    def combine_records(init, record)
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
      writer.close
    end

    def wayfinder
      Wayfinder.for(collection)
    end

    def collection
      query_service.find_by(id: collection_id)
    end

    def query_service
      Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    end
end
