require 'spec_helper'

describe DisplayHelper do

  it 'should return top-level Pegasus Link' do
    pegasus_url = 'http://pegasus.law.columbia.edu'

    link = pegasus_item_link(nil)
    link.should have_text(pegasus_url)
    link.should match(/href=.#{pegasus_url}./)
  end

  it 'should return formats as text when appropriate' do
    # we know that Online uses "link.png"
    document = { 'format' => %w(Purple Online Banana) }
    format_string = formats_with_icons(document)
    format_string.should match /Purple, .*link.png.*Online, Banana/
  end

  it 'generate_value_links() returns unlinked values when appropriate' do
    values = %w(Eeny meeny miny moe)
    out = generate_value_links(values, 'NoSuchCategory')
    out.should == values

    values_delimited = values.map { |element| "#{element}|DELIM|foo" }
    expect do
      generate_value_links(values_delimited, 'NoSuchCategory')
    end.to raise_error(RuntimeError)

    @add_row_style = :text
    values_delimited = values.map { |element| "#{element}|DELIM|foo" }
    out = generate_value_links(values_delimited, 'NoSuchCategory')
    out.should == values
  end

  describe '#catalog_to_openurl_ctx_kev' do
    let(:document) { stub_model SolrDocument }
    context 'music recording' do
      it 'should return valid coin' do
        allow(document).to receive(:[]).with(:author_display)
        allow(document).to receive(:[]).with(:pub_date_sort)
        allow(document).to receive(:[]).with(:format).and_return(["Music - Recording"])
        allow(document).to receive(:[]).with(:isbn_display).and_return(["9780393936872", "0393936872", "9780393936889", "0393936880", "9780393936896"])
        allow(document).to receive(:[]).with(:title_display).and_return(["Norton recorded anthology of western music"])
        allow(document).to receive(:[]).with(:full_publisher_display).and_return(["[United States] : Naxos ; [New York] : W.W. Norton, [2014]", CGI.unescape("%E2%84%972014.")])
        allow(document).to receive(:[]).with(:id).and_return("10922430")
        expect(catalog_to_openurl_ctx_kev(document)).to match(/ctx_ver=Z39.88-2004&rft\.title\=Norton\+recorded\+anthology\+of\+western\+music&rft\.pub\=%5BUnited\+States%5D\+%3A\+Naxos\+%3B\+%5BNew\+York%5D\+%3A\+W\.W\.\+Norton%2C\+%5B2014%5D&rft\.pub\=%E2%84%972014\.&rft\.isbn\=9780393936872\&rft\.isbn\=0393936872\&rft\.isbn\=9780393936889\&rft\.isbn\=0393936880\&rft\.isbn\=9780393936896\&rft_val_fmt\=info\:ofi\/fmt\:kev\:mtx\:dc\&rft\.type\=audioRecording\&rft\.genre=music/)
      end
    end
  end
  describe '#ac_to_openurl_ctx_kev' do
    let(:document) { stub_model SolrDocument }
    context 'music recording' do
      it 'should return valid coin' do
        allow(document).to receive(:[]).with(:title_display).and_return("Chorale Labyrinth")
        allow(document).to receive(:[]).with(:pub_date_sort)
        allow(document).to receive(:[]).with(:publisher)
        allow(document).to receive(:[]).with(:author_facet).and_return(["Patterson, Nick J."])
        allow(document).to receive(:[]).with(:type_of_resource_facet).and_return(["sound recording--musical"])
        allow(document).to receive(:[]).with(:genre_facet).and_return(["Musical compositions"])
        allow(document).to receive(:[]).with(:id).and_return("ac:155943")
        allow(document).to receive(:[]).with(:type_of_resource_mods).and_return("sound recording--musical")
        music_coin = /ctx_ver=Z39\.88-2004&rft_val_fmt=info\:ofi\/fmt\:kev\:mtx\:dc\&rft\.type\=audioRecording\&rft\.genre=music&rft_id\=http%3A%2F%2Facademiccommons\.columbia\.edu%2Fcatalog%2Fac%3A155943&rft\.au=Patterson%2C\+Nick\+J\.&rft\.atitle=Chorale\+Labyrinth/
        expect(ac_to_openurl_ctx_kev(document)).to match(music_coin)
      end
    end
    context 'audio book' do
      pending
      #http://academiccommons.columbia.edu/catalog/ac:175475
    end
    context 'text document' do
      it 'should return valid coin' do
        allow(document).to receive(:[]).with(:id).and_return "ac:161289"
        allow(document).to receive(:[]).with(:record_creation_date).and_return "2012-02-17T14:00:36Z"
        allow(document).to receive(:[]).with(:language).and_return "English"
        allow(document).to receive(:[]).with(:date_issued).and_return "2012"
        allow(document).to receive(:[]).with(:handle).and_return "http://hdl.handle.net/10022/ActionController:P:12608"
        allow(document).to receive(:[]).with(:title_display).and_return "Governing Imperial Borders: Insights from the Study of the Implementation of Law in Qing Xinjiang"
        allow(document).to receive(:[]).with(:author_info).and_return ["Tian, Huan : ht2116 : Columbia University. History"]
        allow(document).to receive(:[]).with(:author_facet).and_return ["Tian, Huan"]
        allow(document).to receive(:[]).with(:author_display).and_return "Tian, Huan"
        allow(document).to receive(:[]).with(:pub_date_facet).and_return ["2012"]
        allow(document).to receive(:[]).with(:genre_facet).and_return ["Dissertations"]
        allow(document).to receive(:[]).with(:subject_facet).and_return ["Asian history"]
        allow(document).to receive(:[]).with(:notes).and_return ["Ph.D., Columbia University."]
        allow(document).to receive(:[]).with(:type_of_resource_mods).and_return ["text"]
        allow(document).to receive(:[]).with(:type_of_resource_facet).and_return ["Text"]
        allow(document).to receive(:[]).with(:organization_facet).and_return ["Columbia University"]
        allow(document).to receive(:[]).with(:department_facet).and_return ["History", "East Asian Languages and Cultures"]
        allow(document).to receive(:[]).with(:publisher)
        allow(document).to receive(:[]).with(:pub_date_sort)
        text_coin = /tx_ver=Z39\.88-2004&rft_val_fmt=info:ofi\/fmt:kev:mtx:journal&rft_id=http%3A%2F%2Facademiccommons\.columbia\.edu%2Fcatalog%2Fac%3A161289&rft\.au=Tian%2C\+Huan&rft\.atitle=Governing\+Imperial\+Borders%3A\+Insights\+from\+the\+Study\+of\+the\+Implementation\+of\+Law\+in\+Qing\+Xinjiang/
        expect(ac_to_openurl_ctx_kev(document)).to match(text_coin)
      end
    end
  end
end
