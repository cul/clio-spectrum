# encoding: UTF-8
module SearchHelper
  # def show_all_search_boxes
  #   (controller.controller_name == 'search' && controller.action_name == 'index') || (params['q'].to_s.empty?  && params['s.q'].to_s.empty? && params['commit'].to_s.empty?)
  # end

  # 1/2014 - this is currently equivalent to active_source alone
  # def active_search_box
  #   con = controller.controller_name
  #   act = controller.action_name
  #
  #   if con == 'search' && act == 'index'
  #     "quicksearch"
  #   elsif act == 'ebooks' || con == 'ebooks'
  #     'ebooks'
  #   else
  #     active_source
  #   end
  # end

  def search_render_options(search, source)
    opts = { 'template' => @search_style }
           .merge(source['render_options'] || {})
           .merge(search['render_options'] || {})
    opts['count'] = search['count'].to_i if search['count']
    opts
  end

  # remove Bootstrap-Dropdown-Menu-as-Select-Tag
  # def dropdown_with_select_tag(name, field_options, field_default = nil, *html_args)
  #   dropdown_options = html_args.extract_options!
  #
  #   dropdown_default = field_options.invert[field_default] || field_options.keys.first
  #   select_options = dropdown_options.delete(:select_options) || {}
  #
  #   result = render(partial: '/dropdown_select', locals: { name: name, field_options: field_options, dropdown_options: dropdown_options, field_default: field_default, dropdown_default: dropdown_default, select_options: select_options })
  # end

  def display_search_boxes(source)
    render(partial: '/_search/search_box', locals: { source: source })
  end

  def display_advanced_search_form(source)
    options = DATASOURCES_CONFIG['datasources'][source]['search_box'] || {}
    blacklight_config = Spectrum::SearchEngines::Solr.generate_config(source)

    if options['search_type'] == 'blacklight' && options['advanced'] == true
      return fix_catalog_links(render('/catalog/advanced_search', localized_params: params), source)
    end

    if options['search_type'] == 'summon' && options['advanced'] == true
      return render '/spectrum/summon/advanced_search', source: source, path: articles_index_path
    end
  end

  def display_basic_search_form(source)
    datasource_config = DATASOURCES_CONFIG['datasources'][active_source] || {}
    options = datasource_config['search_box'] || {}

    search_params = determine_search_params
    div_classes = ['search_box', source]
    # div_classes << "multi" if show_all_search_boxes

    # The "selected" search_box hide/show was built for
    # javascript-based datasource switching.
    # Repurpose for basic/advanced load state.
    # div_classes << "selected" if active_source == source
    div_classes << 'selected' unless has_advanced_params?

    result = ''.html_safe
    if active_source == source

      # BASIC SEARCH INPUT BOX
      classes = 'search_q form-control'
      classes = "#{classes} best-bets-typeahead" if APP_CONFIG['best_bets'].present?
      result += text_field_tag(:q,
                               search_params[:q] || '',
                               class: classes.to_s,
                               id: "#{source}_q",
                               placeholder: options['placeholder'])
      # This focuses, but also selects-all-text in some browsers - yuck
      #   http://stackoverflow.com/questions/4740184
      # , autofocus: true

      ### for blacklight (catalog, academic commons)
      if options['search_type'] == 'blacklight'

        # insert hidden fields
        result += standard_hidden_keys_for_search

      ### for eds (articles)
      elsif options['search_type'] == 'eds'
        if @results.is_a?(Hash) && @results.has_key?("articles")
          # What EDS query values should pass through as hidden inputs?
          # allowed_keys = ['resultsperpage', 'sort', 'f', 'range']
          # TODO - 'f' and 'range' are complex structures - need to figure out how to pass them
          allowed_keys = ['resultsperpage', 'sort']
          
          result += eds_hidden_keys_for_search( params.slice(*allowed_keys) )
        end
        

      ### for summon (articles)
      elsif options['search_type'] == 'summon'

        summon_query_as_hash = {}
        if @results.is_a?(Hash) && @results.values.first.instance_of?(Spectrum::SearchEngines::Summon)
          # when summon fails, these may be nil
          if @results.values.first.search && @results.values.first.search.query
            summon_query_as_hash = @results.values.first.search.query.to_hash
          end
        end

        result += if summon_query_as_hash == {}
                    # If there is no Summon query in-effect, this is a new summon search,
                    # add a param to tell Summon to apply default filter settings.
                    hidden_field_tag 'new_search', 'true'
                  else
                    # Pass through Summon facets, checkboxes, sort, paging, as hidden form variables
                    # For any Summon data-source:  Articles
                    summon_hidden_keys_for_search(summon_query_as_hash.except('s.fq'))
                  end

        # insert hidden fields
        result += hidden_field_tag 'source', active_source || 'articles'
        result += hidden_field_tag 'form', 'basic'
      end

      # Pass along hidden tags for AC API
      if source == 'ac'
        # sticky sort-order when just changing query terms
        result += hidden_field_tag 'sort', params['sort']
        result += hidden_field_tag 'order', params['order']
      end

      # insert drop-down
      if options['search_fields'].is_a?(Hash)
        # remove Bootstrap-Dropdown-Menu-as-Select-Tag
        # result += dropdown_with_select_tag(:search_field, options['search_fields'].invert, h(search_params[:search_field]), title: 'Targeted search options', class: 'search_options')
        search_field_select = select_tag('search_field', options_for_select(options['search_fields'].invert, search_params[:search_field]), class: 'form-control')
        result += content_tag(:div, search_field_select, class: 'form-group')
      end

      # Will this wrap input-text and drop-down-select more nicely?
      # result = content_tag(:div, result, class: "input-group")
      # result = content_tag(:div, result, class: "form-group", style: 'display: inline;')

      # "Search" button
      # result += content_tag(:button, '<span class="glyphicon glyphicon-search icon-white"></span><span class="visible-lg">Search</span>'.html_safe, type: 'submit', class: 'btn basic_search_button btn-primary add-on', name: 'commit', value: 'Search')
      search_button = content_tag(:button, '<span class="glyphicon glyphicon-search icon-white"></span> <span class="visible-lg-inline">Search</span>'.html_safe, type: 'submit', class: 'btn basic_search_button btn-primary form-control', name: 'commit', value: 'Search')

      result += content_tag(:div, search_button, class: 'input-group-btn')

      result = content_tag(:div, result, class: 'input-group')
      # result = content_tag(:div, result, class: "form-group", style: 'display: inline;')

      # link to advanced search
      if options['search_type'].in?('summon', 'blacklight') && options['advanced']
        adv_text = "Advanced#{content_tag(:span, ' Search', class: 'hidden-sm')}".html_safe
        # result += content_tag(:a, 'Advanced Search', class: 'btn btn-link advanced_search_toggle', href: '#')
        result += content_tag(:a, adv_text, class: 'btn btn-link advanced_search_toggle', href: '#')
      end

      result = content_tag(:div, result, class: 'search_row', escape: false)

      raise "no route in #{source} " unless options['route']

      result = content_tag(:form, result, :'accept-charset' => 'UTF-8', :class => 'form-inline', :action => send(options['route']), :method => 'get')

      result = content_tag(:div, result, class: div_classes.join(' '))

    end

    result
  end

  # Override Blacklight's has_search_parameters to handle
  # our additional datasources
  def has_search_parameters?
    # Blacklight's logic, covers Catalog, AC, LWeb
    return true unless params[:q].blank?
    return true unless params[:f].blank?
    return true unless params[:search_field].blank?

    # Consider the empty-query to be an active search param as well.
    # (just "q=", meaning, retrieve ALL documents of this datasource)
    return true if params[:q]

    # Summon params are different...
    # (although we're trying to remove 's.q' from params.)
    return true unless params['s.q'].blank?
    return true unless params['s.fq'].blank?
    return true unless params['s.ff'].blank?

    # No, we found no search parameters
    false
  end

  def display_start_over_link(source = active_source)
    link_to content_tag(:span, '', class: 'glyphicon glyphicon-backward') + ' Start Over',
            datasource_landing_page_path(source),
            class: 'btn btn-default'
    # :class => 'btn btn-link'
  end
end
