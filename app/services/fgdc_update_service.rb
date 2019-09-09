# frozen_string_literal: true
class FgdcUpdateService
  def initialize(file_set:)
    @file_set = file_set
  end

  def insert_onlink(url:)
    onlink = find_or_create_node("//idinfo/citation/citeinfo/onlink")
    onlink.content = url
    save_changes
    update_checksum
  end

  private

    def change_set_persister
      ::ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
        storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)
      )
    end

    def doc
      @doc ||= Nokogiri::XML(file_object.read)
    end

    def file_object
      @file_object ||= Valkyrie::StorageAdapter.find_by(id: original_file.file_identifiers[0])
    end

    # Finds or recursively creates node from xpath string
    def find_or_create_node(xpath_string)
      base_path = "/"
      nodes = xpath_string.gsub("//", "").split("/")
      nodes.each do |node|
        current_path = "#{base_path}/#{node}"
        unless doc.at_xpath(current_path)
          new_node = Nokogiri::XML::Node.new(node, doc)
          doc.at_xpath(base_path).add_child(new_node)
        end
        base_path = current_path
      end

      doc.at_xpath(xpath_string)
    end

    def original_file
      @file_set.original_file
    end

    def save_changes
      filepath = file_object.io.path
      File.write(filepath, doc.to_xml)
    end

    def update_checksum
      original_file.checksum = MultiChecksum.for(file_object)
      updated_change_set = ChangeSet.for(@file_set)
      change_set_persister.buffer_into_index do |buffered_persister|
        buffered_persister.save(change_set: updated_change_set)
      end
    end
end
