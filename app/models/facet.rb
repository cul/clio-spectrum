class Facet
  attr_reader :source, :facet, :label, :limit, :items

  def initialize(source, options = {})
    case source
    when Summon::Facet
      parse_summon(source, options)
      
    end
  end 

  def items(select = :all)
    @items.select { |i| select == :all || i[:status] == select }.sort do |x,y| 
      sort = y[:count] <=> x[:count] 
      sort == 0 ? x[:label] <=> y[:label] : sort
    end
  end

  private

  def parse_summon(facet, options)

    @source = :summon
    @facet = facet
    @label = facet.display_name
    @limit = options.delete(:limit) || 15
    @items = facet.counts.collect do |item|
      parse_summon_item(item)
    end
  end

  def parse_summon_item(item)
    result = {}

    result[:status] = :not_selected
    result[:status] = :selected if item.applied?
    result[:status] = :negated if item.negated?

    result[:count] = item.count.to_i
    result[:label] = item.value 

    result
  end
  
end
