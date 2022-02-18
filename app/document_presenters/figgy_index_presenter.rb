# frozen_string_literal: true

class FiggyIndexPresenter < ::Blacklight::IndexPresenter
  ##
  # Overrides https://github.com/projectblacklight/blacklight/blob/v6.11.2/app/presenters/blacklight/index_presenter.rb#L24
  # to use semicolon-join instead of to_sentence
  #
  # Render the document index heading
  #
  # @param [Symbol, Proc, String] field_or_string_or_proc Render the given field or evaluate the proc or render the given string
  # @param [Hash] opts
  # TODO: the default field should be `document_show_link_field(doc)'
  def label(field_or_string_or_proc, opts = {})
    config = Blacklight::Configuration::NullField.new
    value = case field_or_string_or_proc
            when Symbol
              config = field_config(field_or_string_or_proc)
              Array.wrap(document[field_or_string_or_proc]).join("; ")
            when Proc
              field_or_string_or_proc.call(document, opts)
            when String
              field_or_string_or_proc
    end

    value ||= document.id
    field_values(config, value: value)
  end
end
