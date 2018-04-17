# frozen_string_literal: true
module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  def render_document_heading(*args)
    options = args.extract_options!
    document = args.first
    tag = options.fetch(:tag, :h4)
    document ||= @document

    # escape manually to allow <br /> to go through unescaped
    val = Array.wrap(presenter(document).heading).map { |v| h(v) }.join("<br />")
    content_tag(tag, val, { itemprop: "name", dir: val.to_s.dir }, false)
  end

  def can_edit?
    can? :update, resource
  end

  def can_manage_files?
    can? :file_manager, resource
  end

  def can_manage_structure?
    can? :structure, resource
  end

  def can_delete?
    can? :destroy, resource
  end

  def can_create_template_from?
    can?(:edit, resource) && can?(:create, Template)
  end

  def can_create_ephemera_folder_for?
    can?(:edit, resource) && can?(:create, EphemeraFolder)
  end

  def can_download?
    can? :download, resource
  end
end
