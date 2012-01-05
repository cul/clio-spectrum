require 'spec_helper'

describe 'basic' do
  it 'passes basic math' do
    assert_equal 2+2, 5
    (2+2).should == 4
  end
end
