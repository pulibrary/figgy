class ChangeSetPersister
  class ApplyBannerImageId
    attr_reader :change_set_persister, :change_set
    delegate :query_service, :persister, to: :change_set_persister
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
    end

    def run
      return unless change_set.respond_to?(:banner_image_id)
      return unless change_set.changed?(:banner_image_url)
      change_set.validate(banner_image_id: banner_image_id)
      change_set.sync
      change_set
    end

    private

      def banner_image_id
        return nil unless change_set.banner_image_url
        return nil unless change_set.banner_image_url.include?(Figgy.config["pyramidal_url"])
        id = extract_id_from_url(change_set.banner_image_url)
        file_set = query_service.custom_queries.find_by_property(property: :file_metadata, model: FileSet, value: { id: Valkyrie::ID.new(id.to_s) }).first
        return nil unless file_set
        Wayfinder.for(file_set).parent.id.to_s
      end

      def extract_id_from_url(url)
        # Get the url path components as an array
        path = url.gsub(Figgy.config["pyramidal_url"], "").split("/")
        # Decode the iiif id and get the figgy file id. Example:
        #   20%2F2b%2Ff5%2F202bf5e644d14b78a8183ea9219c5d4e%2Fintermediate_file ->
        #   20/2b/f5/202bf5e644d14b78a8183ea9219c5d4e/intermediate_file ->
        #   202bf5e644d14b78a8183ea9219c5d4e
        id = URI.decode_www_form_component(path[0]).split("/")[3]
        # Convert string back into a UUID
        id.gsub(/\A(.{8})(.{4})(.{4})(.{4})(.{12})\z/, '\1-\2-\3-\4-\5')
      end
  end
end
