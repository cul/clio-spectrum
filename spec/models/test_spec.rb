require 'spec_helper'

describe 'basic' do
  it 'passes basic math' do
    assert_equal 2 + 2, 4
    expect(2 + 2).to eq 4

  end
end
