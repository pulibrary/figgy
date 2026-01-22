class TemplateDecorator < Valkyrie::ResourceDecorator
  def template_label
    title.first
  end
end
