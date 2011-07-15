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
end
