# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def application_name
    APP_CONFIG[:application_name].to_s
  end

  def alternating_line(id="default")
    @alternating_line ||= Hash.new("odd")
    @alternating_line[id] = @alternating_line[id] == "even" ? "odd" : "even"
  end
  

  def alternating_bit(id="default")
    @alternating_bits ||= Hash.new(1)
    @alternating_bits[id] = 1 - @alternating_bits[id]
  end

  def auto_add_empty_spaces(text)
    text.to_s.gsub(/([^\s-]{5})([^\s-]{5})/,'\1&#x200B;\2')
  end

  # determines if the given document id is in the folder
  def item_in_folder?(doc_id)
    session[:folder_document_ids] && session[:folder_document_ids].include?(doc_id.listify.first) ? true : false
  end


  def add_row(title, value, options = {})
    options.reverse_merge!( {
      :display_blank => false,
      :display_only_first => false,
      :join => "<br/>",
      :abbreviate => nil,
      :html_safe => true,
      :style => :definition
    })

    values = value.listify
    
    values = values.collect { |txt| txt.to_s.abbreviate(options[:abbreviate]) } if options[:abbreviate]
    value_txt = options[:display_only_first] ? values.first.to_s :  values.join(options[:join]).to_s
    value_txt = value_txt.html_safe if options[:html_safe]  
    result = ""
    if options[:display_blank] || !value_txt.empty?
      
      result = content_tag(:div, :class => "row") do
        if options[:style] == :definition
         content_tag(:div, title.to_s, :class => "label") + content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "value")
        elsif options[:style] == :blockquote
          content_tag(:div, content_tag(:div, value_txt, :class => "value_box"), :class => "blockquote")
        end
          
      end

    end

    result
  end
end
