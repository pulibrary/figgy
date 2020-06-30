# frozen_string_literal: true

class ViewerController < ApplicationController
  layout "viewer_layout"
  def index
    render :index
  end
end
