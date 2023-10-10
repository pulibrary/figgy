# frozen_string_literal: true
class ChangeSetPersister
  class UpdateCloudFilePermissions
    attr_reader :change_set_persister, :change_set, :resource
    def initialize(change_set_persister:, change_set:, post_save_resource: nil)
      @change_set = change_set
      @change_set_persister = change_set_persister
      @resource = change_set.resource
    end

    def run
      return unless needs_updating?
      cloud_files.each do |cloud_file|
        key = cloud_file.file_identifiers.first.to_s.gsub("cloud-geo-derivatives-shrine://", "")
        CloudFilePermissionsService.new(resource: resource, key: key).run
      end
    end

    private

      def needs_updating?
        return false unless resource.respond_to?(:visibility) && change_set.changed?(:visibility)
        return false unless resource.decorate.respond_to?(:geo_members)
        return false if cloud_files.blank?
        true
      end

      def cloud_files
        @cloud_files ||= resource.decorate.geo_members.map(&:cloud_derivative_files).flatten
      end
  end
end
