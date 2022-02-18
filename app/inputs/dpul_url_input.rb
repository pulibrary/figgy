# frozen_string_literal: true

# A custom input class for the slug field; adapted directly from the simple form
# docs
class DpulUrlInput < SimpleForm::Inputs::Base
  def input(wrapper_options)
    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

    "<span class=\"form-inline\">https://dpul.princeton.edu/#{@builder.text_field(attribute_name, merged_input_options)}</span>".html_safe
  end
end
# rubocop:enable Rails/OutputSafety
