require 'spec_helper'


describe DisplayHelper do

  it "pegasus_item_link(nil) should return top-level Pegasus Link" do
    pegasus_url = 'http://pegasus.law.columbia.edu'

    link = pegasus_item_link(nil)
    link.should have_text( pegasus_url )
    link.should match(/href=.#{pegasus_url}./)

  end

end


