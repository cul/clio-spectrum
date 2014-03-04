require 'spec_helper'




describe Spectrum::SearchEngines::GoogleAppliance do

  it "should raise RuntimeError if no 'q' param passed" do
    expect {
      Spectrum::SearchEngines::GoogleAppliance.new()
    }.to raise_error(RuntimeError)
  end


end



# BROKEN
# need to call private function, 
# with input arguments,
# and support a call to Rails params()
# 
# describe SpectrumController do
# 
#   it "should raise RuntimeError if invalid datasource passed" do
#     # helper.stub!(:params).and_return {}
#     sc = SpectrumController.new()
#     sc.stub!(:params).and_return {}
#     expect {
#       sc.send(:get_results,  ['NoSuchDatasource'])
#     }.to raise_error(RuntimeError)
#   end
# 
# 
# end



