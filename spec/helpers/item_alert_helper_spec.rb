require 'spec_helper'

describe ItemAlertHelper do
  it 'excercise helper - classes and text messages' do
    # Create the first user (author_id 1)
    FactoryBot.build(:user)

    item_alert = FactoryBot.build(:item_alert)
    expect(item_alert).not_to be_nil

    # Starts in the future - NOT ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: '2050-01-01', end_date: nil)
    expect(render_alert_duration(item_alert)).to start_with 'Starts 01/01/2050'
    expect(alert_status(item_alert)).to eq 'info'

    # Starts in the past - ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: '2000-01-01', end_date: nil)
    expect(render_alert_duration(item_alert)).to start_with 'Started 01/01/2000'
    expect(alert_status(item_alert)).to eq 'success'

    # Ends in the past - NOT ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: nil, end_date: '2000-01-01')
    expect(render_alert_duration(item_alert)).to start_with 'Ended 01/01/2000'
    expect(alert_status(item_alert)).to eq 'danger'

    # Ends in the future - ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: nil, end_date: '2050-01-01')
    expect(render_alert_duration(item_alert)).to start_with 'Ends 01/01/2050'
    expect(alert_status(item_alert)).to eq 'success'

    # No times set - ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: nil, end_date: nil)
    expect(render_alert_duration(item_alert)).to eq 'Forever'
    expect(alert_status(item_alert)).to eq 'success'

    # From past to future - ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: '2000-01-01', end_date: '2050-01-01')
    expect(render_alert_duration(item_alert)).to eq '01/01/2000 00:00 - 01/01/2050 00:00'
    expect(alert_status(item_alert)).to eq 'success'

    # From future to past - NOT ACTIVE
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: '2050-01-01', end_date: '2000-01-01')
    expect(render_alert_duration(item_alert)).to eq '01/01/2050 00:00 - 01/01/2000 00:00'
    expect(alert_status(item_alert)).to eq 'info'

    # Starts in the past, ends VERY SOON
    tomorrow = DateTime.now + 1.day
    item_alert = FactoryBot.build(:item_alert,
                                  start_date: '2000-01-01', end_date: tomorrow)
    expect(alert_status(item_alert)).to eq 'warning'
  end
end
