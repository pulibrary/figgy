# frozen_string_literal: true
module MetsStructure
  def structure
    structure_type('Logical') || default_structure
  end

  def structure_for_volume(volume_id)
    return {} if structureless?
    volume = logical_node_for_volume(volume_id) || volume_nodes.find { |vol| vol.attribute("ID").value == volume_id }
    { nodes: structure_for_nodeset(volume.element_children) }
  end

  def file_label(file_id)
    struct = structure_map('Physical')
    node = struct.xpath(".//mets:fptr[@FILEID='#{file_id}']").first if struct
    (label_from_hierarchy(node.parent) if node) || label_from_related_objects(file_id)
  end

  private

    def logical_node_for_volume(volume_id)
      logical_node = @mets.xpath("/mets:mets/mets:structLink/mets:smLink[@xlink:from='#{volume_id}']")[0]
      return if logical_node.blank?
      @mets.xpath("//mets:div[@ID='#{logical_node['xlink:to']}']")[0]
    end

    def structure_map(type)
      @mets.xpath("/mets:mets/mets:structMap[@TYPE='#{type}']").first
    end

    def structureless?
      false
    end

    def structure_type(type)
      return nil unless structure_map(type)
      top = structure_map(type).xpath("mets:div/mets:div")
      return nil if top.empty?
      { nodes: structure_for_nodeset(top) }
    end

    def default_structure
      { nodes: structure_for_nodeset(structure_map('RelatedObjects').xpath("mets:div/mets:div[@TYPE = 'OrderedList']/mets:div")) }
    end

    def structure_for_nodeset(nodeset)
      nodes = []
      nodeset.each do |node|
        nodes << structure_recurse(node)
      end
      nodes
    end

    def structure_recurse(node)
      children = node.element_children
      return single_file_object(children.first) if !section(node) && single_file(children)

      child_nodes = []
      if single_file(children)
        child_nodes = [single_file_object(children.first)]
      else
        children.each do |child|
          child_nodes << structure_recurse(child)
        end
      end
      { label: node['LABEL'], nodes: child_nodes }
    end

    def section(node)
      node.attributes["TYPE"].try(:value) == "Section"
    end

    def single_file(nodeset)
      nodeset.length == 1 && nodeset.first.name == 'fptr'
    end

    def single_file_object(node)
      id = node['FILEID']
      label = label_from_hierarchy(node.parent) || label_from_related_objects(id)
      { label: label, proxy: id }
    end

    def label_from_hierarchy(node)
      return nil unless node['LABEL']
      current = node
      label = current['LABEL']
      while current.parent['LABEL'] && in_scope(current.parent)
        label = "#{current.parent['LABEL']}. #{label}"
        current = current.parent
      end
      label
    end

    def in_scope(node)
      multi_volume? ? node.parent.parent.name == 'div' : node.parent.name == 'div'
    end

    def label_from_related_objects(id)
      @mets.xpath("/mets:mets/mets:structMap[@TYPE='RelatedObjects']//mets:div[mets:fptr/@FILEID='#{id}']/@LABEL").to_s
    end
end
