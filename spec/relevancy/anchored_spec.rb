require 'spec_helper'

describe 'Anchored searches', :skip_travis do

  # NEXT-1059 - "Title begins with" doesn't work with non-filing characters
  it "should work with non-filing characters" do
    starts_with = '{!qf=$title_start_qf pf=$title_start_pf}'
    q1 = '"The Wills eye manual"'
    q2 = '"Wills eye manual"'
    q3 = '"The Wills eye manual office and emergency room"'
    q4 = '"Wills eye manual office and emergency room"'

    [q1, q2, q3, q4].each { |q|
      resp = solr_resp_doc_ids_only(q: "#{starts_with}#{q}")
      expect(rank(resp, 6613582)).to be <= 3
      expect(rank(resp, 8364149)).to be <= 3
      expect(rank(resp, 10026137)).to be <= 3
      expect(rank(resp, 12309484)).to be <= 4

      # NOT:  "Wills hospital eye manual for nurses"
      expect(rank(resp, 4019811)).to be > 3

      # If we ever get more in our catalog, bump this up.
      expect(resp.size).to eq 4
    }

  end

end


