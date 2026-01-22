class StructureDecorator < Valkyrie::ResourceDecorator
  def form_label
    label.first
  end
end
