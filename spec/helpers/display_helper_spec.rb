require 'spec_helper'


describe DisplayHelper do

  it "should return top-level Pegasus Link" do
    pegasus_url = 'http://pegasus.law.columbia.edu'

    link = pegasus_item_link(nil)
    link.should have_text( pegasus_url )
    link.should match(/href=.#{pegasus_url}./)
  end

  it "should return formats as text when appropriate" do
    # we know that Online uses "link.png"
    document = { 'format' => [ 'Purple', 'Online', 'Banana']}
    format_string = formats_with_icons(document)
    format_string.should match /Purple, .*link.png.*Online, Banana/
  end


  it "generate_value_links() returns unlinked values when appropriate" do
    values = ['Eeny', 'meeny', 'miny', 'moe']
    out = generate_value_links( values, 'NoSuchCategory' )
    out.should == values

    values_delimited = values.collect { |element| "#{element}|DELIM|foo"}
    expect {
      generate_value_links( values_delimited, 'NoSuchCategory' )
    }.to raise_error(RuntimeError)

    @add_row_style = :text
    values_delimited = values.collect { |element| "#{element}|DELIM|foo"}
    out = generate_value_links( values_delimited, 'NoSuchCategory' )
    out.should == values
  end


end


