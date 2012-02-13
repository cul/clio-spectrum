#encoding: UTF-8
module SearchHelper
  def show_all_search_boxes
    (controller.controller_name == 'search' && controller.action_name == 'index') || (params['q'].to_s.empty?  && params['s.q'].to_s.empty? && params['commit'].to_s.empty?)
  end

  def active_search_box
    con = controller.controller_name
    act = controller.action_name

    if con == 'search' && act == 'index'
      "Quicksearch"
    elsif act == 'ebooks' || con == 'ebooks'
      'eBooks'
    else
      @active_source
    end
  end

  def display_search_box(source, &block)
    div_classes = ["search_box", datasource_to_class(source)]
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
