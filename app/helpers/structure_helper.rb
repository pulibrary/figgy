# frozen_string_literal: true
module StructureHelper
  def structure_page_header
    h = tag.h1("Structure Manager")
    h += bulk_edit_breadcrumb
    h
  end

  def legacy_structure_page_header
    h = tag.h1("Structure Manager (Legacy)")
    h += legacy_bulk_edit_breadcrumb
    h
  end

  private

    def bulk_edit_breadcrumb
      tag.nav do
        tag.ol(class: "breadcrumb") do
          (bulk_edit_parent_work + header)
        end
      end
    end

    def legacy_bulk_edit_breadcrumb
      tag.nav do
        tag.ol(class: "breadcrumb") do
          (bulk_edit_parent_work + legacy_header)
        end
      end
    end

    def bulk_edit_parent_work
      return "" unless @change_set.resource
      link = tag.a(@change_set.resource.decorate.header,
                         title: @change_set.id,
                         href: bulk_edit_parent_path(@change_set, @parent))
      tag.li(class: "breadcrumb-item") do
        link
      end
    end

    def header
      tag.li("Structure Manager", class: "breadcrumb-item active")
    end

    def legacy_header
      tag.li("Structure Manager (Legacy)", class: "breadcrumb-item active")
    end

    def bulk_edit_parent_path(change_set, _parent)
      solr_document_path(change_set)
    end
end
