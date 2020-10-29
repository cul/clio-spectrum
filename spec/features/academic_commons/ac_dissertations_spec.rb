
require 'spec_helper'

describe 'Academic Commons Dissertations search' do

  it 'should return fewer results than AC search' do
    
    visit ac_index_path(q: 'test')
    ac_search_total_results = 
    ac_total_items = all('.current_item_info').first['data-total-items'].to_i
    
    visit ac_index_path(q: 'test', datasource: 'ac_dissertations')
    ac_dissertations_total_items = all('.current_item_info').first['data-total-items'].to_i

    # print "ac_total_items=#{ac_total_items}"
    # print "ac_dissertations_total_items=#{ac_dissertations_total_items}"
    
    expect(ac_dissertations_total_items).to be < ac_total_items
    
  end
  
end


