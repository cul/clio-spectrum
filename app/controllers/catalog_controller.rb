require 'blacklight/catalog'

class CatalogController < ApplicationController

  include Blacklight::Catalog



  def show
    extra_head_content << view_context.auto_discovery_link_tag(:unapi, unapi_url, {:type => 'application/xml',  :rel => 'unapi-server', :title => 'unAPI' })
    @response, @document = get_solr_response_for_doc_id    

    unless @document
      flash[:error] = "Item not found."
      redirect_to root_path 
    end

    respond_to do |format|
      format.html {setup_next_and_previous_documents; render :layout => "no_sidebar"}

      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons. 
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name), :layout => false }
      end

    end
  end


end

