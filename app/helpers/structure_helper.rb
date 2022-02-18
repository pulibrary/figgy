# frozen_string_literal: true

module StructureHelper
  def structure_page_header
    h = content_tag(:h1, "Structure Manager")
    h += bulk_edit_breadcrumb
    h
  end

  private

    def bulk_edit_breadcrumb
      content_tag(:ul, class: "breadcrumb") do
        (bulk_edit_parent_work + header)
      end
    end

    def bulk_edit_parent_work
      return "" unless @change_set.resource
      link = content_tag(:a, @change_set.resource.decorate.header,
        title: @change_set.id,
        href: bulk_edit_parent_path(@change_set, @parent))
      content_tag(:li, link)
    end

    def header
      content_tag(:li, "Structure Manager", class: :active)
    end

    def bulk_edit_parent_path(change_set, parent)
      ContextualPath.new(child: change_set, parent_id: parent.try(:id)).show
    end
end
