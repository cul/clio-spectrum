require_dependency 'vendor/plugins/blacklight/app/controllers/catalog_controller.rb' 

class CatalogController < ApplicationController
  # get single document from the solr index
  def show
    extra_head_content << @template.auto_discovery_link_tag('application/xml', unapi_url, {:rel => 'unapi-server', :title => 'unAPI' })

    @response, @document = get_solr_response_for_doc_id    
    respond_to do |format|
      format.html {setup_next_and_previous_documents; render :layout => "no_sidebar"}
      
      # Add all dynamically added (such as by document extensions)
      # export formats.
      @document.export_formats.each_key do | format_name |
        # It's important that the argument to send be a symbol;
        # if it's a string, it makes Rails unhappy for unclear reasons. 
        format.send(format_name.to_sym) { render :text => @document.export_as(format_name) }
      end
      
    end
  end



end

