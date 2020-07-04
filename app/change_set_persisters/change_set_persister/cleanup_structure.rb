# frozen_string_literal: true
#
# A persistence handler for removing StructureNode objects from a resource's logical_structure
class ChangeSetPersister
  class CleanupStructure
    attr_reader :change_set_persister, :change_set
    delegate :resource, to: :change_set

    def initialize(change_set_persister:, change_set:)
      @change_set_persister = change_set_persister
      @change_set = change_set
    end

    # Retrieve parent, if any. rescursively search logical_strucutre for nodes with the id of the
    # resource being deleted and remove them.
    def run
      parents.each do |parent|
        parent_change_set = ChangeSet.for(parent)
        next unless parent_change_set.respond_to? :logical_structure
        parent_change_set.logical_structure.each do |structure|
          recursive_delete(structure.nodes, @change_set.id)
        end
        parent_change_set.validate({})
        change_set_persister.save(change_set: parent_change_set)
      end
    end

    private

      def parents
        Valkyrie::MetadataAdapter.find(:indexing_persister).query_service.find_inverse_references_by(resource: resource, property: :member_ids).to_a
      end

      def recursive_delete(nodes, id_to_remove)
        nodes.each do |node|
          if node.proxy.include? id_to_remove
            nodes.delete(node)
          else
            next if node.nodes.empty?
            recursive_delete(node.nodes, id_to_remove)
          end
        end
      end
  end
end
