require 'spec_helper'

describe 'database_routing', :js => true do
  it 'routes the database_index properly' do
    visit catalog_index_path
    raise page.html
  end
end
