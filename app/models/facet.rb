class Facet
  attr_reader :source, :facet, :label, :limit, :items

  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED
  # UNUSED

  # def initialize(source, options = {})
  #   case source
  #   when Summon::Facet
  #     parse_summon(source, options)
  # 
  #   end
  # end
  # 
  # def items(*select)
  #   select ||= [:all]
  #   @items.select { |i| select.include?(:all) || select.include?(i[:status]) }.sort do |x,y|
  #     sort = y[:count] <=> x[:count]
  #     sort == 0 ? x[:label] <=> y[:label] : sort
  #   end
  # end
  # 
  # private
  # 
  # def parse_summon(facet, options)
  # 
  #   @source = :summon
  #   @facet = facet
  #   @label = facet.display_name
  #   @limit = options.delete(:limit) || 15
  #   @items = facet.counts.collect do |item|
  #     parse_summon_item(item)
  #   end
  # end
  # 
  # def parse_summon_item(item)
  #   result = {}
  # 
  #   if item.negated?
  #     result[:status] = :negated
  #     result[:commands] = { :remove => {'s.cmd' => item.remove_command}}
  #   elsif item.applied?
  #     result[:status] = :selected
  #     result[:commands] = { :remove => {'s.cmd' => item.remove_command}}
  #   else
  #     result[:status] = :not_selected
  #     result[:commands] = { :select => {'s.cmd' => item.apply_command}, :negate => {'s.cmd' => item.apply_negated_command}}
  #   end
  # 
  # 
  #   result[:count] = item.count.to_i
  #   result[:label] = item.value
  # 
  #   result
  # end

end
