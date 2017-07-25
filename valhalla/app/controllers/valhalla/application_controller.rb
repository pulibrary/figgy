# frozen_string_literal: true
module Valhalla
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
  end
end
