require 'ipaddr'

class ClicktaleController < ApplicationController
  def show

    send_file(File.join(Rails.root, "public/clicktale", params[:filename] + ".html"), :type => :html, :disposition => "inline")

    # if clicktale_config[:allowed_addresses] && ip_allowed?(request.remote_ip)
    #   send_file(File.join(Rails.root, "tmp/clicktale", params[:filename] + ".html"), :type => :html, :disposition => "inline")
    # else
    #   render :text => "Not Found", :status => 404
    # end
    
    # Clean up temp files
    # Fires only after ClickTale fetches, 
    # over-clearing just means a handful of samples go missing.
    cache_dir = Rails.root + "/public/clicktale"
    Dir.glob(cache_dir + "/clicktale_*.html") do |clicktale_file|
      begin
        File.delete(clicktale_file) if File.exist?(clicktale_file)
      rescue Exception => e
        Rails.logger.error "[ClickTale] exception raised during cleanup: #{e.message}"
      end
    end
    
  end

  private
  def ip_allowed?(ip)
    clicktale_config[:allowed_addresses].split(",").any? do |ip_string|
      IPAddr.new(ip_string).include?(ip)
    end
  end
end

