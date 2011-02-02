require 'vendor/plugins/blacklight/app/helpers/application_helper.rb'
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def application_name
    "CLIO New Arrivals"
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

end
