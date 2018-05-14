# frozen_string_literal: false
module BoundingBoxHelper
  include ::BlacklightHelper

  # rubocop:disable Rails/OutputSafety
  def bbox_input(property, change_set)
    markup = ""
    markup << %(<div id='bbox'></div>)
    markup << bbox_display_inputs
    markup << bbox_edit_script_tag(property, change_set)
    markup.html_safe
  end

  def bbox_display(coverage)
    markup = ""
    markup << %(<tr><th></th>\n<td id='accordion'><ul class='tabular'>)
    markup << %(<div id='bbox' class='collapse in'></div>)
    markup << bbox_display_inputs
    markup << bbox_display_script_tag(coverage)
    markup << toggle_button
    markup << %(</ul></td></tr>)
    markup.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def toggle_button
    %(
      <a data-toggle='collapse' data-parent='accordion' href='#bbox' class='btn btn-default'>
       Toggle Map</a>
      )
  end

  ##
  # Returns script tag markup for loading the bounding box selector.
  # @param[Symbol] name of property that holds bounding box string
  # @return[String] script tag
  def bbox_edit_script_tag(property, change_set)
    %(
      <script>
        boundingBoxSelector({inputId: #{bbox_input_id(property, change_set)}});
      </script>
    )
  end

  def bbox_display_script_tag(coverage)
    %(
      <script>
        boundingBoxSelector({coverage: '#{coverage}', readonly: true});
      </script>
    )
  end

  def bbox_input_id(property, change_set)
    "#{change_set.resource.class.name.underscore}_#{property}"
  end

  ##
  # Returns markup for a row of read only bounding box inputs.
  # @return[String]
  # rubocop:disable MethodLength
  def bbox_display_inputs
    %(
      <div class="row bbox-inputs">
        <div class="col-md-3">
          <div class="input-group">
            <span class="input-group-addon"><div>North</div></span>
            <input readonly id="bbox-north" type="text" class="form-control bbox-input">
          </div>
        </div>
        <div class="col-md-3">
          <div class="input-group">
            <span class="input-group-addon"><div>East</div></span>
            <input readonly id="bbox-east" type="text" class="form-control bbox-input">
          </div>
        </div>
        <div class="col-md-3">
          <div class="input-group">
            <span class="input-group-addon"><div>South</div></span>
            <input readonly id="bbox-south" type="text" class="form-control bbox-input">
          </div>
        </div>
        <div class="col-md-3">
          <div class="input-group">
            <span class="input-group-addon"><div>West</div></span>
            <input readonly id="bbox-west" type="text" class="form-control bbox-input">
          </div>
        </div>
      </div>
    )
  end
  # rubocop:enable MethodLength
end
