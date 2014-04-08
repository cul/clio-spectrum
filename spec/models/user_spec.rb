require 'spec_helper'

describe 'User' do

  before(:each) do
    # @user = User.new
  end

  # For the current list of on-campus IP ranges, see:
  #   https://library.columbia.edu/bts/cerm/vendor_data.html#network
  # Extend this list of examples as needed to cover edge cases.
  ON_CAMPUS_EXAMPLES = [
    '128.59.1.1',
    '129.236.1.1',
    '156.111.1.1',
    '156.145.1.1',
    '160.39.1.1',
    '192.12.82.1',
    '192.5.43.1',
    '207.10.136.1',
    '207.10.143.1',
    '209.2.47.1',
    '209.2.48.1',
    '209.2.51.1',
    '209.2.185.1',
    '209.2.208.1',
    '209.2.223.1',
    '209.2.224.1',
    '209.2.239.1',
  ]

  # Extend this list of examples as needed to assure correctness.
  OFF_CAMPUS_EXAMPLES = [
    '1.1.1.1',
    '10.0.0.1',
    '172.16.0.1',
    '192.168.1.1',
    '240.0.0.1',
  ]

  describe 'IP-addr lookups' do

    OFF_CAMPUS_EXAMPLES.each do |ip|
      it 'when checking an off-campus IP (' + ip + ')' do
        Benchmark.realtime do
          User.on_campus?(ip).should be_false
        end.should be < 0.010, 'should run in under 10ms'
      end
    end

    ON_CAMPUS_EXAMPLES.each do |ip|
      it 'when checking an on-campus IP (' + ip + ')' do
        Benchmark.realtime do
          User.on_campus?(ip).should be_true
        end.should be < 0.010, 'should run in under 10ms'
      end
    end
  end

  # end

end
