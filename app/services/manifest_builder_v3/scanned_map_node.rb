# frozen_string_literal: true
class ManifestBuilderV3
  class ScannedMapNode < RootNode
    def manifestable_members
      @manifestable ||= Wayfinder.for(resource).members.reject { |x| x.is_a?(RasterResource) }
    end

    def members
      @members ||= manifestable_members.map do |member|
        wayfinder = Wayfinder.for(member)
        if wayfinder.respond_to?(:decorated_scanned_maps) && wayfinder.decorated_scanned_maps.empty?
          wayfinder.geo_members.first
        else
          member
        end
      end.compact
    end

    def leaf_nodes
      @leaf_nodes ||= members.select { |x| x.instance_of?(FileSet) && geo_image?(x) }
    end

    def logical_structure
      value = resource.try(:logical_structure) || []

      # Return an empty structure if the structure contains empty nodes.
      nodes = value.first.nodes.reject { |n| n.nodes.empty? }
      return [] if nodes.empty?
      value
    end

    private

      def geo_image?(member)
        ControlledVocabulary.for(:geo_image_format).include?(member.mime_type.first)
      end
  end
end
