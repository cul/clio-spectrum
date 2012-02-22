require 'blacklight/catalog'

class CatalogController < ApplicationController
  before_filter :by_source_config

  include Blacklight::Catalog

  configure_blacklight do |config|


    





    config.add_search_field 'all_fields', :label => 'All Fields'
    
    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5

  end

  def index


    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")

    (@response, @document_list) = get_search_results
    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params; render :layout => 'quicksearch' }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end
  end


  def show
    @response, @document = get_solr_response_for_doc_id    

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

  # when a request for /catalog/BAD_SOLR_ID is made, this method is executed...
  def invalid_solr_id_error
    if Rails.env == "development"
      render # will give us the stack trace
    else
      flash[:notice] = "Sorry, you have requested a record that doesn't exist."
      redirect_to root_path
    end

  end


end

