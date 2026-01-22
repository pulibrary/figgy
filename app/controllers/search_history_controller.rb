class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  helper RangeLimitHelper
end
