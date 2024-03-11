# frozen_string_literal: true
class CaptionDecorator < Valkyrie::ResourceDecorator
  def caption_label
    label = ControlledVocabulary.for(:language).label(object.caption_language)
    label += " (Original)" if original_language_caption
    label
  end
end
