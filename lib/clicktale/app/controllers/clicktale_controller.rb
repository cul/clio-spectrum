require 'rails'
require 'ipaddr'

class ClicktaleController < ApplicationController
  def show

    cache_token = params[:filename]
    Rails.logger.debug "[ClickTale] Rails.root=[#{Rails.root}]..."
    Rails.logger.debug "[ClickTale] cache_token=[#{cache_token}]..."
    Rails.logger.debug "[ClickTale] request.remote_ip=[#{request.remote_ip}]..."

    begin
      # Only send back file to ip's in our approved list
      if clicktale_config[:allowed_addresses] && ip_allowed?(request.remote_ip)
        Rails.logger.debug "[ClickTale] sending file..."
        send_file(File.join(Rails.root, "public/clicktale", "clicktale_#{cache_token}.html"), :type => :html, :disposition => "inline")
      else
        Rails.logger.debug "[ClickTale] Not Found..."
        render :text => "Not Found", :status => 404
      end
    rescue ActionController::MissingFile => e
      # This is fine, it means that clicktale.com tried to harvest a cached
      # page from us, but we'd already removed it via housekeeping.
      # The result is a single missed reading, which is perfectly ok.
      Rails.logger.debug "[ClickTale] ActionController::MissingFile"
      render :text => "Not Found", :status => 404
    end

    # Clean up temp files
    # Fires only after ClickTale fetches, 
    # over-clearing just means a handful of samples go missing.
    cache_dir = File.join(Rails.root, "public/clicktale")
    Rails.logger.debug "[ClickTale] scanning cache_dir=[#{cache_dir}]..."
    # Find any cached html, except don't remove the file satisfying the current request
    Dir.glob(cache_dir + "/clicktale_*.html").reject { |f| f.include?(cache_token) }.each do |clicktale_file|
      Rails.logger.debug "[ClickTale] found clicktale_file=[#{clicktale_file}]"
      begin
        File.delete(clicktale_file) if File.exist?(clicktale_file)
        # Delete gzipped versions of Rails cache files, if present
        zipfile = clicktale_file + ".gz"
        File.delete(zipfile) if File.exist?(zipfile)
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

