require 'spec_helper'

describe 'coins encoding for zotero' do
  context 'search results' do
    context 'catalog' do
      context 'music recording' do
        it 'has the correct coins format' do
          visit catalog_index_path('q' => 'psalm 21 meyerbeer', 'format'=> 'Music Recording')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(CGI.unescape (coin)['title']).to match(/fmt:kev:mtx:dc&rft\.type=audioRecording/)
          end
        end
      end
      context 'printed book' do
        it 'has the correct coins format' do
          visit catalog_index_path('q' => 'penguins', 'format'=> 'Book')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(CGI.unescape (coin)['title']).to match(/fmt:kev:mtx:book/)
          end
        end
      end
      context 'video recording' do
        it 'has the correct coins format' do
          visit catalog_index_path('q' => 'Labyrinth', 'format'=> 'Video')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(CGI.unescape (coin)['title']).to match(/fmt:kev:mtx:dc&rft\.type=videoRecording/)
          end
        end
      end
    end
    context 'academic commons' do
      context 'music recording' do
        it 'has the correct coins format' do
          visit academic_commons_index_path('q' => 'Chorale Labyrinth')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(CGI.unescape (coin)['title']).to match(/fmt:kev:mtx:dc&rft\.type=audioRecording/)
          end
        end
      end
      context 'video recording' do
        it 'has the correct coins format' do
          visit academic_commons_index_path('q' => 'Video for the cases A9 to A12 for a still observer',
                                           'rows' => 5)
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(CGI.unescape (coin)['title']).to match(/fmt:kev:mtx:dc&rft\.type=videoRecording/)
          end
        end
      end
    end
  end

  context 'single item' do
    context 'music recording' do
      it 'has the correct coins format' do
        visit catalog_path 10922430
        coins = CGI.unescape find("//span[@class='Z3988']")['title']
        expect(coins).to match(/fmt:kev:mtx:dc&rft\.type=audioRecording/)
      end
    end
    context 'printed book' do
      it 'has the correct coins format' do
        visit catalog_path 4359539
        coins = CGI.unescape find("//span[@class='Z3988']")['title']
        expect(coins).to match(/fmt:kev:mtx:book/)
      end
    end
    context 'ebook' do
      it 'has the correct coins format' do
        visit catalog_path 7928264
        coins = CGI.unescape find("//span[@class='Z3988']")['title']
        expect(coins).to match(/fmt:kev:mtx:book/)
      end
    end
    context 'video recording' do
      it 'has the correct coins format' do
        visit catalog_path 9340283
        coins = CGI.unescape find("//span[@class='Z3988']")['title']
        expect(coins).to match(/fmt:kev:mtx:dc&rft\.type=videoRecording/)
      end
    end
    context 'sound recording' do
      it 'has the correct coins format' do
        visit catalog_path 10903311
        coins = CGI.unescape find("//span[@class='Z3988']")['title']
        expect(coins).to match(/fmt:kev:mtx:dc&rft\.type=audioRecording/)
      end
    end
  end
end
