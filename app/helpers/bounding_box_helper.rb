# frozen_string_literal: false
module BoundingBoxHelper
  include ::BlacklightHelper

  # rubocop:disable Rails/OutputSafety
  def bbox_input(property, change_set)
    markup = ""
    markup << %(<div id='bbox' data-coverage='#{change_set.resource.coverage}' data-input-id='#{bbox_input_id(property, change_set)}'></div>)
    markup << bbox_display_inputs
    markup.html_safe
  end

  def bbox_display(coverage)
    markup = ""
    markup << %(<tr><th></th>\n<td><ul class='tabular'>)
    markup << %(<div id="mapPanel" class="collapse show"><div id='bbox' data-coverage='#{coverage}' data-read-only='true'></div></div>)
    markup << bbox_display_inputs
    markup << toggle_button
    markup << %(</ul></td></tr>)
    markup.html_safe
  end
  # rubocop:enable Rails/OutputSafety

  def toggle_button
    %(
      <a data-toggle="collapse" href="#mapPanel" class="btn btn-outline-secondary" role="button" aria-expanded="true" aria-controls="mapPanel">
       Toggle Map</a>
      )
  end

  def bbox_input_id(property, change_set)
    "#{change_set.resource.class.name.underscore}_#{property}"
  end

  ##
  # Returns markup for a row of read only bounding box inputs.
  # @return[String]
  # rubocop:disable Metrics/MethodLength
  def bbox_display_inputs
    %(
      <div class="row bbox-inputs">
        <div class="col-md-3">
          <div class="input-group">
            <div class="input-group-prepend">
              <span class="input-group-text"><div>North</div></span>
            </div>
            <input readonly id="bbox-north" type="text" class="form-control bbox-input">
          </div>
        </div>
        <div class="col-md-3">
          <div class="input-group">
            <div class="input-group-prepend">
              <span class="input-group-text"><div>East</div></span>
            </div>
            <input readonly id="bbox-east" type="text" class="form-control bbox-input">
          </div>
        </div>
        <div class="col-md-3">
          <div class="input-group">
            <div class="input-group-prepend">
              <span class="input-group-text"><div>South</div></span>
            </div>
            <input readonly id="bbox-south" type="text" class="form-control bbox-input">
          </div>
        </div>
        <div class="col-md-3">
          <div class="input-group">
            <div class="input-group-prepend">
              <span class="input-group-text"><div>West</div></span>
            </div>
            <input readonly id="bbox-west" type="text" class="form-control bbox-input">
          </div>
        </div>
      </div>
    )
  end
  # rubocop:enable Metrics/MethodLength
end
