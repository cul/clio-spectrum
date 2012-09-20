require 'blacklight/catalog'

class CatalogController < ApplicationController
  before_filter :by_source_config

  include Blacklight::Catalog
  include BlacklightUnapi::ControllerExtension


  def index


    extra_head_content << view_context.auto_discovery_link_tag(:rss, url_for(params.merge(:format => 'rss')), :title => "RSS for results")
    extra_head_content << view_context.auto_discovery_link_tag(:atom, url_for(params.merge(:format => 'atom')), :title => "Atom for results")
    params['extra_solr_source'] = @active_datasource

    (@response, @document_list) = get_and_debug_search_results
    add_alerts_to_documents(@document_list)
    @filters = params[:f] || []

    respond_to do |format|
      format.html { save_current_search_params; render :layout => 'quicksearch' }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
    end

    
  end

  # updates the search counter (allows the show view to paginate)
  def update
    adjust_for_results_view
    session[:search][:counter] = params[:counter]
    case @active_source
    when 'Databases'
      redirect_to databases_show_path
    when 'eJournals'
      redirect_to ejournals_show_path
    else

      redirect_to :action => "show"
    end
  end

  def show
    @response, @document = get_solr_response_for_doc_id    
    add_alerts_to_documents(@document)

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

  private

  def add_alerts_to_documents(documents)
    DatabaseAlert.find_all_by_clio_id(Array.wrap(documents).collect(&:id)).each do |alert|
      document = documents.detect { |doc| doc.id.to_s == alert.clio_id.to_s }
      document["database_alert"] = alert.message
    end
  end
end

