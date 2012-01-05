require 'spec_helper'

describe 'basic' do
  it 'passes basic math' do
    assert_equal 2+2, 4
    (2+2).should == 5
  end
end
