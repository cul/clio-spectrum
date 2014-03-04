require 'spec_helper'


describe DatasourcesHelper do

  it "should throw exception on unknown datasource" do
    expect {
      datasource_landing_page_path('NoSuchDatasource', 'MySearchQuery')
    }.to raise_error(RuntimeError)
  end

end



describe DisplayHelper do

  it "should throw exception when no partial to render" do
    expect {
      render_first_available_partial(['no_such_partial', 'another_one'], {})
    }.to raise_error(RuntimeError)
  end



end