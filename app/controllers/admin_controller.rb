# The beginnings of an administrative interface for managing
# the Systems side of the application.
# 
# 10/13 - this class is unused
# 
class AdminController < ApplicationController
  layout "no_sidebar_no_search"

  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED

  # def ingest_log
  #   @filename = File.join(Rails.root.to_s, "log", Rails.env.to_s + "_ingest.log")
  #   if File.exists?(@filename)
  #     @log = IO.readlines(@filename).reverse
  #   end
  # end
end
