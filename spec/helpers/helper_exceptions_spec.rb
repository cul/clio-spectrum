require 'spec_helper'

describe DatasourcesHelper do

  it 'should throw be silent on unknown datasource' do
    expect do
      datasource_landing_page_path('NoSuchDatasource', 'MySearchQuery')
    end.not_to raise_error()
  end

end

describe DisplayHelper do

  it 'should throw exception when no partial to render' do
    expect do
      render_first_available_partial(%w(no_such_partial another_one), {})
    end.to raise_error(RuntimeError)
  end

end
