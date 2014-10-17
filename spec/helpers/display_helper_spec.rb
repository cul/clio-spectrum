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
    it 'should set author to unknown if author is missing' do
      allow(document).to receive(:[]).with(:author_display).and_return(nil)
      allow(document).to receive(:[]).with(:format).and_return(["Music - Recording"])
      allow(document).to receive(:[]).with(:id).and_return("10922430")
      allow(document).to receive(:[]).with(:isbn_display).and_return(["9780393936872", "0393936872", "9780393936889", "0393936880", "9780393936896"])
      allow(document).to receive(:[]).with(:pub_name_display).and_return(["Naxos", "W.W. Norton"])
      allow(document).to receive(:[]).with(:pub_place_display).and_return(["United States", "New York"])
      allow(document).to receive(:[]).with(:pub_year_display).and_return(["2014", "℗2014"])
      allow(document).to receive(:[]).with(:title_display).and_return(["Norton recorded anthology of western music"])
      allow(document).to receive(:[]).with(:subject_topic_facet).and_return(["Musical analysis", "Music appreciation"])
      allow(document).to receive(:[]).with(:subject_form_facet).and_return(["Music collections"])
      allow(document).to receive(:[]).with(:subject_geo_facet).and_return(["Antarctica"])
      allow(document).to receive(:[]).with(:subject_era_facet).and_return(["Ice Age"])
      coin = catalog_to_openurl_ctx_kev(document)
      expect(coin).to match('rft.au=unknown')
    end
    context 'music recording' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:author_display).and_return(nil)
        allow(document).to receive(:[]).with(:format).and_return(["Music - Recording"])
        allow(document).to receive(:[]).with(:id).and_return("10922430")
        allow(document).to receive(:[]).with(:isbn_display).and_return(["9780393936872", "0393936872", "9780393936889", "0393936880", "9780393936896"])
        allow(document).to receive(:[]).with(:pub_name_display).and_return(["Naxos", "W.W. Norton"])
        allow(document).to receive(:[]).with(:pub_place_display).and_return(["United States", "New York"])
        allow(document).to receive(:[]).with(:pub_year_display).and_return(["2014", "℗2014"])
        allow(document).to receive(:[]).with(:title_display).and_return(["Norton recorded anthology of western music"])
        allow(document).to receive(:[]).with(:subject_topic_facet).and_return(["Musical analysis", "Music appreciation"])
        allow(document).to receive(:[]).with(:subject_form_facet).and_return(["Music collections"])
        allow(document).to receive(:[]).with(:subject_geo_facet).and_return(["Antarctica"])
        allow(document).to receive(:[]).with(:subject_era_facet).and_return(["Ice Age"])
        coin = catalog_to_openurl_ctx_kev(document)
        music_coin = /ctx_ver=Z39\.88-2004&rft.au=unknown&rft\.title=Norton\+recorded\+anthology\+of\+western\+music&rft\.pub=Naxos&rft.pub=W.W.+Norton&rft\.date=2014&rft\.date=%E2%84%972014&rft\.place=United\+States&rft\.place=New\+York&rft\.isbn=9780393936872&rft\.isbn=0393936872&rft\.isbn=9780393936889&rft\.isbn=0393936880&rft\.isbn=9780393936896&rft.subject=Musical\+analysis&rft.subject=Music\+appreciation&rft.subject=Music\+collections&rft.subject=Antarctica&rft.subject=Ice\+Age&rft_val_fmt=info\:ofi\/fmt\:kev\:mtx\:dc&rft\.type=audioRecording$/
        expect(coin).to match(music_coin)
      end
    end
    context 'non-musical sound recording' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:author_display).and_return(["Cosby, Bill, 1937-"])
        allow(document).to receive(:[]).with(:format).and_return(["Sound Recording"])
        allow(document).to receive(:[]).with(:full_publisher_display).and_return(["Burbank, Calif. : Warner Bros. Records, [1964]"])
        allow(document).to receive(:[]).with(:id).and_return("10903311")
        allow(document).to receive(:[]).with(:isbn_display)
        allow(document).to receive(:[]).with(:pub_name_display)
        allow(document).to receive(:[]).with(:pub_year_display).and_return(["1964"])
        allow(document).to receive(:[]).with(:pub_place_display).and_return(["Burbank, Calif"])
        allow(document).to receive(:[]).with(:title_display).and_return(["I started out as a child [sound recording] : the wit of Bill Cosby"])
        allow(document).to receive(:[]).with(:subject_topic_facet)
        allow(document).to receive(:[]).with(:subject_form_facet)
        allow(document).to receive(:[]).with(:subject_geo_facet)
        allow(document).to receive(:[]).with(:subject_era_facet)
        coin = catalog_to_openurl_ctx_kev(document)
        sound_coin = /ctx_ver=Z39\.88-2004&rft\.au=Cosby%2C\+Bill%2C\+1937-&rft\.title=I\+started\+out\+as\+a\+child\+%5Bsound\+recording%5D\+%3A\+the\+wit\+of\+Bill\+Cosby&rft\.date=1964&rft\.place=Burbank%2C\+Calif&rft_val_fmt=info\:ofi\/fmt\:kev\:mtx\:dc&rft\.type=audioRecording$/
        expect(coin).to match(sound_coin)
      end
    end
    context 'video' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:author_display).and_return(nil)
        allow(document).to receive(:[]).with(:format).and_return(["Video"])
        allow(document).to receive(:[]).with(:id).and_return("9340283")
        allow(document).to receive(:[]).with(:isbn_display).and_return(nil)
        allow(document).to receive(:[]).with(:pub_name_display).and_return(["Columbia TriStar Home Entertainment"])
        allow(document).to receive(:[]).with(:pub_year_display).and_return(["2003"])
        allow(document).to receive(:[]).with(:pub_place_display).and_return(["Culver City, Calif."])
        allow(document).to receive(:[]).with(:title_display).and_return(["Labyrinth [videorecording (DVD)]"])
        allow(document).to receive(:[]).with(:subject_topic_facet)
        allow(document).to receive(:[]).with(:subject_form_facet)
        allow(document).to receive(:[]).with(:subject_geo_facet)
        allow(document).to receive(:[]).with(:subject_era_facet)
        coin = catalog_to_openurl_ctx_kev(document)
        video_coin = /ctx_ver=Z39\.88-2004&rft\.au=unknown&rft\.title=Labyrinth\+%5Bvideorecording\+%28DVD%29%5D&rft\.pub=Columbia\+TriStar\+Home\+Entertainment&rft\.date=2003&rft\.place=Culver\+City%2C\+Calif\.&rft_val_fmt=info:ofi\/fmt:kev:mtx:dc&rft\.type=videoRecording$/
        expect(coin).to match(video_coin)
      end
    end
    context 'book' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:author_display).and_return(["Troy, Nancy J."])
        allow(document).to receive(:[]).with(:format).and_return(["Book"])
        allow(document).to receive(:[]).with(:id).and_return("25566")
        allow(document).to receive(:[]).with(:isbn_display).and_return(["0894670115"])
        allow(document).to receive(:[]).with(:pub_name_display).and_return(["Yale University Art Gallery"])
        allow(document).to receive(:[]).with(:pub_year_display).and_return(["1964"])
        allow(document).to receive(:[]).with(:pub_place_display).and_return(["Burbank, Calif"])
        allow(document).to receive(:[]).with(:title_display).and_return(["Mondrian and neo-plasticism in America"])
        allow(document).to receive(:[]).with(:subject_topic_facet)
        allow(document).to receive(:[]).with(:subject_form_facet)
        allow(document).to receive(:[]).with(:subject_geo_facet)
        allow(document).to receive(:[]).with(:subject_era_facet)
        coin = catalog_to_openurl_ctx_kev(document)
        book_coin = /ctx_ver=Z39\.88-2004&rft\.au=Troy%2C\+Nancy\+J\.&rft\.title=Mondrian\+and\+neo-plasticism\+in\+America&rft\.pub=Yale\+University\+Art\+Gallery&rft\.date=1964&rft\.place=Burbank%2C\+Calif&rft\.isbn=0894670115&rft_val_fmt=info:ofi\/fmt:kev:mtx:dc&rft\.type=book&rft\.btitle=Mondrian\+and\+neo-plasticism\+in\+America&rft\.genre=book$/
        expect(coin).to match(book_coin)
      end
    end
  end
  describe '#ac_to_openurl_ctx_kev' do
    let(:document) { stub_model SolrDocument }
    context 'music recording' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:author_facet).and_return(["Patterson, Nick J."])
        allow(document).to receive(:[]).with(:id).and_return("ac:155943")
        allow(document).to receive(:[]).with(:publisher)
        allow(document).to receive(:[]).with(:pub_date_sort)
        allow(document).to receive(:[]).with(:title_display).and_return("Chorale Labyrinth")
        allow(document).to receive(:[]).with(:type_of_resource_mods).and_return("sound recording--musical")
        music_coin = /ctx_ver=Z39\.88-2004&rft_val_fmt=info\:ofi\/fmt\:kev\:mtx\:dc\&rft\.type\=audioRecording\&rft\.title=Chorale\+Labyrinth\&rft_id\=http%3A%2F%2Facademiccommons\.columbia\.edu%2Fcatalog%2Fac%3A155943&rft\.au=Patterson%2C\+Nick\+J\.$/
        coin = ac_to_openurl_ctx_kev(document)
        expect(coin).to match(music_coin)
      end
    end
    context 'non-musical sound recording' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:type_of_resource_mods).and_return(["sound recording--nonmusical"])
        allow(document).to receive(:[]).with(:author_facet).and_return(["Geis, Shannon"])
        allow(document).to receive(:[]).with(:id).and_return("ac:175475")
        allow(document).to receive(:[]).with(:publisher)
        allow(document).to receive(:[]).with(:pub_date_sort)
        allow(document).to receive(:[]).with(:title_display).and_return("Ambiguous Borders")
        sound_coin = /ctx_ver=Z39\.88-2004&rft_val_fmt=info\:ofi\/fmt\:kev\:mtx\:dc\&rft\.type\=audioRecording\&rft\.title=Ambiguous\+Borders\&rft_id\=http%3A%2F%2Facademiccommons\.columbia\.edu%2Fcatalog%2Fac%3A175475&rft\.au=Geis%2C\+Shannon$/
        coin = ac_to_openurl_ctx_kev(document)
        expect(coin).to match(sound_coin)
      end
    end
    context 'text document' do
      it 'should return correct coin' do
        allow(document).to receive(:[]).with(:author_facet).and_return "Tian, Huan"
        allow(document).to receive(:[]).with(:id).and_return "ac:161289"
        allow(document).to receive(:[]).with(:publisher)
        allow(document).to receive(:[]).with(:title_display).and_return "Governing Imperial Borders: Insights from the Study of the Implementation of Law in Qing Xinjiang"
        allow(document).to receive(:[]).with(:type_of_resource_mods).and_return ["text"]
        allow(document).to receive(:[]).with(:pub_date_sort)
        text_coin = /tx_ver=Z39\.88-2004&rft_val_fmt=info:ofi\/fmt:kev:mtx:journal\&rft\.atitle=Governing\+Imperial\+Borders%3A\+Insights\+from\+the\+Study\+of\+the\+Implementation\+of\+Law\+in\+Qing\+Xinjiang\&rft_id=http%3A%2F%2Facademiccommons\.columbia\.edu%2Fcatalog%2Fac%3A161289&rft\.au=Tian%2C\+Huan$/
        coin = ac_to_openurl_ctx_kev(document)
        expect(coin).to match(text_coin)
      end
    end
  end
end
