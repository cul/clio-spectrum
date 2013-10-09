require 'spec_helper'

describe LocationsController do

  describe "Reloading Fixtures" do
    it "Should not change the Location count" do
      before = Location.count
      before.should >= 20

      Location.clear_and_load_fixtures!

      after = Location.count
      after.should >= 20

      before.should == after

    end
  end

end
