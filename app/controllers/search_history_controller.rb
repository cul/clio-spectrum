class SearchHistoryController < ApplicationController
  include Blacklight::SearchHistory

  helper BlacklightRangeLimit::ViewHelperOverride
  helper RangeLimitHelper
end
