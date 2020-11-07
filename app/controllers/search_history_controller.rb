# frozen_string_literal: true

class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  helper BlacklightRangeLimit::ViewHelperOverride
  helper RangeLimitHelper
end
