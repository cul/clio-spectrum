require 'spec_helper'

describe HoldingsHelper do

  it 'should return JavaScript links for non-http services' do
    non_http_services = %w(precat on_order in_process)
    fake_bib = '1999'
    linkset = service_links(non_http_services, fake_bib)

    expect(linkset.length).to eq non_http_services.length

    (0 .. non_http_services.length - 1).each do |i|
      # lookup definition, then from this infer the anchor text and href
      definition = HoldingsHelper::SERVICES[ non_http_services[i]]
      expected_text = definition[0]
      expected_href = definition[1] + '(' + fake_bib + ')'

      # the link returned from the helper method should match expectations
      link       = linkset[i]
      expect(link).to have_text(expected_text)
      expect(link).to match /#{expected_href}/
    end

  end
end
