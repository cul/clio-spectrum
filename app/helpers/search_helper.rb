#encoding: UTF-8
module SearchHelper

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
