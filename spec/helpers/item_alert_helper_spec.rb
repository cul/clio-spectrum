require 'spec_helper'


describe ItemAlertHelper do

  it "excercise helper - classes and text messages" do
    item_alert = FactoryGirl.create(:item_alert)
    item_alert.should_not be_nil


    # Starts in the future - NOT ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => '2050-01-01', :end_date => nil)
    render_alert_duration(item_alert).should start_with 'Starts 01/01/2050'
    alert_status(item_alert).should eq 'info'

    # Starts in the past - ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => '2000-01-01', :end_date => nil)
    render_alert_duration(item_alert).should start_with 'Started 01/01/2000'
    alert_status(item_alert).should eq 'success'

    # Ends in the past - NOT ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => nil, :end_date => '2000-01-01')
    render_alert_duration(item_alert).should start_with 'Ended 01/01/2000'
    alert_status(item_alert).should eq 'error'

    # Ends in the future - ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => nil, :end_date => '2050-01-01')
    render_alert_duration(item_alert).should start_with 'Ends 01/01/2050'
    alert_status(item_alert).should eq 'success'

    # No times set - ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => nil, :end_date => nil)
    render_alert_duration(item_alert).should eq 'Forever'
    alert_status(item_alert).should eq 'success'

    # From past to future - ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => '2000-01-01', :end_date => '2050-01-01')
    render_alert_duration(item_alert).should eq '01/01/2000 00:00 - 01/01/2050 00:00'
    alert_status(item_alert).should eq 'success'

    # From future to past - NOT ACTIVE
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => '2050-01-01', :end_date => '2000-01-01')
    render_alert_duration(item_alert).should eq '01/01/2050 00:00 - 01/01/2000 00:00'
    alert_status(item_alert).should eq 'info'

    # Starts in the past, ends VERY SOON
    tomorrow = DateTime.now + 1.day
    item_alert = FactoryGirl.create(:item_alert, 
        :start_date => '2000-01-01', :end_date => tomorrow)
    alert_status(item_alert).should eq 'warning'

  end
end
