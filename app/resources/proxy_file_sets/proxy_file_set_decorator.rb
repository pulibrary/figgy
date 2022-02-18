# frozen_string_literal: true

class ProxyFileSetDecorator < Valkyrie::ResourceDecorator
  display :label,
    :visibility,
    :proxied_file_id

  display_in_manifest [:label]

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end
end
