# frozen_string_literal: true
class FolderJSONImporter
  attr_reader :file, :attributes, :change_set_persister
  delegate :metadata_adapter, to: :change_set_persister
  delegate :persister, to: :metadata_adapter
  def initialize(file:, attributes:, change_set_persister:)
    @file = file
    @attributes = attributes
    @change_set_persister = change_set_persister
  end

  def import!
    file_resources.map do |resource|
      Valkyrie.logger.info("Ingesting #{resource.title}")
      resource.validate(attributes)
      change_set_persister.save(change_set: resource)
    end.to_a
  end

  private

    def file_resources
      @file_resources ||=
        file_content.map do |resource_content|
          EphemeraFolderChangeSet.new(
            EphemeraFolder.new(
              title: resource_content["title"],
              sort_title: resource_content["sort_title"],
              local_identifier: resource_content["ids"]["pudl"],
              identifier: resource_content["ids"]["ark"],
              date_created: resource_content.date_created,
              width: resource_content["dimensions"]["width"].to_s,
              height: resource_content["dimensions"]["height"].to_s,
              creator: resource_content.names.map { |x| x["label"] },
              language: resource_content.language,
              geographic_origin: resource_content.geo_origin,
              subject: resource_content.subject,
              page_count: resource_content["files"].length.to_s
            ),
            files: files(resource_content)
          )
        end
    end

    def file_content
      @file_content ||= JSON.parse(file.read).lazy.map do |resource|
        FileResource.new(resource, change_set_persister)
      end
    end

    def files(resource_content)
      resource_content["files"].map do |file|
        path = pudl_root.join(file["path"].gsub("pudl_root:", ""))
        IngestableFile.new(
          file_path: path,
          mime_type: "image/tiff",
          original_filename: path.basename,
          copyable: true
        )
      end
    end

    def pudl_root
      Pathname.new(Figgy.config["pudl_root"].to_s)
    end

    class FileResource
      attr_reader :resource, :change_set_persister
      delegate :each, :[], to: :resource
      delegate :metadata_adapter, to: :change_set_persister
      delegate :query_service, :persister, to: :metadata_adapter
      def initialize(resource, change_set_persister)
        @resource = resource
        @change_set_persister = change_set_persister
      end

      def date_created
        return if self["date_created"] == "Unknown"
        self["date_created"]
      end

      def names
        self["names"] || []
      end

      def language
        return if resource["language"].blank?
        @language ||= find_or_create_term_by(label: ISO_639.find_by_code(resource["language"]).english_name.split(";").first).id
      end

      def geo_origin
        return if resource["geo_origin"].blank?
        @geo_origin ||= find_or_create_term_by(label: resource["geo_origin"]).id
      end

      def find_or_create_term_by(label:)
        query_service.custom_queries.find_ephemera_term_by_label(label: label) ||
          persister.save(resource: EphemeraTerm.new(label: label, member_of_vocabulary_id: imported_vocabulary.id))
      end

      def imported_vocabulary
        @imported_vocabulary ||= find_or_create_vocabulary_by(label: "Imported Terms")
      end

      def find_or_create_vocabulary_by(label:, vocabulary_id: nil)
        query_service.custom_queries.find_ephemera_vocabulary_by_label(label: label) ||
          persister.save(resource: EphemeraVocabulary.new(label: label, member_of_vocabulary_id: vocabulary_id))
      end

      def find_or_create_subject_by(category:, topic:)
        query_service.custom_queries.find_ephemera_term_by_label(label: topic, parent_vocab_label: category) ||
          create_subject_by(category: category, topic: topic)
      rescue
        create_subject_by(category: category, topic: topic)
      end

      def create_subject_by(category:, topic:)
        vocabulary = find_or_create_vocabulary_by(label: category, vocabulary_id: imported_vocabulary.id)
        persister.save(resource: EphemeraTerm.new(label: topic, member_of_vocabulary_id: vocabulary.id))
      end

      def subject
        resource["subjects"].uniq.map do |sub|
          find_or_create_subject_by(category: sub["category"], topic: sub["topic"]).id
        end
      end
    end
end
