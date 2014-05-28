require 'spec_helper'

describe 'Anchored searches' do

  # NEXT-1059 - "Title begins with" doesn't work with non-filing characters
  it "should work with non-filing characters" do
    starts_with = '{!qf=$title_start_qf pf=$title_start_pf}'
    q1 = '"The Wills eye manual"'
    q2 = '"Wills eye manual"'
    q3 = '"The Wills eye manual office and emergency room"'
    q4 = '"Wills eye manual office and emergency room"'

    [q1, q2, q3, q4].each { |q|
      resp = solr_resp_doc_ids_only(q: "#{starts_with}#{q}")
      resp.should include('6613582').in_first(3).results
      resp.should include('8364149').in_first(3).results
      resp.should include('10026137').in_first(3).results

      # NOT:  "Wills hospital eye manual for nurses"
      resp.should_not include('4019811').in_first(3).results

      # If we ever get more in our catalog, bump this up.
      resp.should have_at_least(3).documents
      resp.should have_at_most(3).documents

    }

  end

end


