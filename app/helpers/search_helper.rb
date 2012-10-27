#encoding: UTF-8
module SearchHelper
  def show_all_search_boxes
    (controller.controller_name == 'search' && controller.action_name == 'index') || (params['q'].to_s.empty?  && params['s.q'].to_s.empty? && params['commit'].to_s.empty?)
  end

  def active_search_box
    con = controller.controller_name
    act = controller.action_name

    if con == 'search' && act == 'index'
      "quicksearch"
    elsif act == 'ebooks' || con == 'ebooks'
      'ebooks'
    else
      @active_source
    end
  end

  def dropdown_with_select_tag(name, field_options, field_default = nil, *html_args)

    dropdown_options = html_args.extract_options!

    dropdown_default = field_options.invert[field_default] || field_options.keys.first
    select_options = dropdown_options.delete(:select_options) || {}
    
    result = render(:partial => "/dropdown_select", :locals => { name: name, field_options: field_options, dropdown_options: dropdown_options, field_default: field_default, dropdown_default: dropdown_default, select_options: select_options })
    

  end

  def display_search_form(source, options = {})
    

    search_params = determine_search_params 
    div_classes = ["search_box", source]
    div_classes << "multi" if show_all_search_boxes
    div_classes << "selected" if active_search_box == source
    

    result = "".html_safe
    if show_all_search_boxes || active_search_box == source
      result += text_field_tag(:q, search_params[:q], class: "", id: "#{source}_q", placeholder: options['placeholder'])
      result += content_tag(:button, '<i class="icon-search icon-white"></i> Search'.html_safe, type: "submit", class: "btn btn-primary", name: 'commit', value: 'Search')

      if options['search_type'] == "blacklight"
        result += search_as_hidden_fields(:omit_keys => [:q, :search_field, :qt, :page, :categories]).html_safe         
        if options['search_fields'].kind_of?(Hash) 
          result += dropdown_with_select_tag(:search_field, options['search_fields'].invert, h(search_params[:search_field]), :title => "Targeted search options", :class=>"") 
        end
      elsif options['search_type'] == "summon"
          
          hidden_field_tag 'category', search_params['category'] || 'articles'
          hidden_field_tag "new_search", "articles"
      end

      result = content_tag(:div, result, class: 'search_row input-append', escape: false)
      raise "no route in #{source} " unless options['route']
      result = content_tag(:form, result, :'accept-charset' => 'UTF-8', :class=> "form-inline", :action => self.send(options['route']), :method => 'get')
      result = content_tag(:div, result, :class => div_classes.join(" "))


      

    end

    return result
  end


  def display_search_box(source, &block)
    div_classes = ["search_box", source]
    div_classes << "multi" if show_all_search_boxes
    div_classes << "selected" if active_search_box == source

    if show_all_search_boxes || active_search_box == source
      content_tag(:div, capture(&block), :class => div_classes.join(" "))
    else
      ""
    end
  end

  def previous_page(search)
    if search.page <= 1
      content_tag('span', "« Previous", :class => "prev prev_page disabled")
    else
      content_tag('span', content_tag('a', "« Previous", :href => search.previous_page), :class => "prev prev_page")
    end
  end

  def next_page(search)
    if search.page >= search.page_count
      content_tag('span', "Next »", :class => "next next_page disabled")
    else
      content_tag('span', content_tag('a', "Next »", :href => search.next_page), :class => "next next_page")
    end
  end

  def page_links(search)
    max_page = [search.page_count, 20].min
    results = [1,2] + ((-5..5).collect { |i| search.page + i }) + [max_page - 1, max_page]

    results = results.reject { |i| i <= 0 || i > [search.page_count,20].min}.uniq.sort
  
    previous = 1 
    results.collect do |page|
      page_delimited = number_with_delimiter(page)
      result = if page == search.page
        content_tag('span', page_delimited, :class => 'page current')
      elsif page - previous > 1
        content_tag('span', "...", :class => 'page gap') + 
          content_tag('span', content_tag('a', page_delimited, :href => search.set_page(page)), :class => 'page')
      else
        content_tag('span', content_tag('a', page_delimited, :href => search.set_page(page)), :class => 'page')
      end

      previous = page
      result

    end.join("").html_safe
  
  end
end
