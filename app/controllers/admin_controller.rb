class AdminController < ApplicationController
  layout "no_sidebar_no_search"

  def ingest_log
    @filename = File.join(Rails.root.to_s, "log", Rails.env.to_s + "_ingest.log")
    if File.exists?(@filename)
      @log = IO.readlines(@filename).reverse
    end
  end
end
