module CucumberHelpers

  def find_result(id)
    return find(".result:nth-of-type(#{id.to_i})")
  end

  def find_field(node, field_name)
   node.all('.row').detect { |row|  row.find('.label').text == field_name }
  end

end

World(CucumberHelpers)
