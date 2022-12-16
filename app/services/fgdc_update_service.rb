# frozen_string_literal: true
class FgdcUpdateService
  def self.insert_onlink(file_set)
    new(file_set: file_set).insert_onlink
  end

  attr_reader :file_set
  def initialize(file_set:)
    @file_set = file_set
  end

  def insert_onlink(url: download_url)
    onlink = find_or_create_node("//idinfo/citation/citeinfo/onlink")
    onlink.content = url
    doc.to_xml
  end

  private

    def download_url
      return unless parent_resource && geo_member_file_set
      path = url_helpers.download_path(resource_id: geo_member_file_set.id, id: geo_member_file_set.primary_file.id)
      "#{protocol}://#{host}#{path}"
    end

    def doc
      @doc ||= Nokogiri::XML(file_object.read)
    end

    def file_object
      @file_object ||= Valkyrie::StorageAdapter.find_by(id: primary_file.file_identifiers[0])
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

    def geo_member_file_set
      @geo_member_file_set ||= parent_resource.geo_members.try(:first)
    end

    def host
      Figgy.default_url_options[:host]
    end

    def primary_file
      @file_set.primary_file
    end

    def protocol
      Figgy.default_url_options[:protocol] || "http"
    end

    def parent_resource
      @parent_resource ||= file_set.decorate.parent
    end

    def url_helpers
      Rails.application.routes.url_helpers
    end
end
