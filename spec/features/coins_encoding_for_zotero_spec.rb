require 'spec_helper'

describe 'coins encoding for zotero', :vcr do

  context 'search results' do

    context 'catalog' do

      context 'music recording' do
        it 'has the correct coins format' do
          visit catalog_index_path('q' => 'psalm 21 meyerbeer', 'f[format][]' => 'Music Recording')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(coin[:title]).to have_text 'fmt:kev:mtx:dc&rft.type=audioRecording'
          end
        end
      end


      context 'printed book' do
        it 'has the correct coins format' do
          visit catalog_index_path('q' => 'penguins', 'f[format][]' => 'Book')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(coin[:title]).to have_text 'fmt:kev:mtx:dc&rft.type=book'
          end
        end
      end

      context 'video recording' do
        it 'has the correct coins format' do
          visit catalog_index_path('q' => 'Labyrinth', 'f[format][]' => 'Video')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(coin[:title]).to have_text 'fmt:kev:mtx:dc&rft.type=videoRecording'
          end
        end
      end
    end

    context 'academic commons' do

      context 'music recording' do
        it 'has the correct coins format' do
          visit academic_commons_index_path('q' => 'Chorale Labyrinth', 'search_field' => 'title')
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(coin[:title]).to have_text 'fmt:kev:mtx:dc&rft.type=audioRecording'
          end
        end
      end

      context 'video recording' do
        it 'has the correct coins format' do
          visit academic_commons_index_path('q' => 'Video for the cases A9 to A12 for a still observer',
                                           'rows' => 5)
          coins = all "//span[@class='Z3988']"
          coins.each do |coin|
            expect(coin[:title]).to have_text 'fmt:kev:mtx:dc&rft.type=videoRecording'
          end
        end
      end

    end
  end

  context 'single item' do

    context 'music recording' do
      it 'has the correct coins format' do
        visit solr_document_path 10922430
        coins = find("//span[@class='Z3988']")['title']
        expect(coins).to have_text 'fmt:kev:mtx:dc&rft.type=audioRecording'
      end
    end

    context 'printed book' do
      it 'has the correct coins format' do
        visit solr_document_path 4359539
        coins = find("//span[@class='Z3988']")['title']
        expect(coins).to have_text 'fmt:kev:mtx:dc&rft.type=book'
      end
    end

    context 'ebook' do
      it 'has the correct coins format' do
        visit solr_document_path 11095272
        coins = find("//span[@class='Z3988']")['title']
        expect(coins).to have_text 'fmt:kev:mtx:dc&rft.type=book'
      end
    end

    context 'video recording' do
      it 'has the correct coins format' do
        visit solr_document_path 9340283
        coins = find("//span[@class='Z3988']")['title']
        expect(coins).to have_text 'fmt:kev:mtx:dc&rft.type=videoRecording'
      end
    end

    context 'sound recording' do
      it 'has the correct coins format' do
        visit solr_document_path 10903311
        coins = find("//span[@class='Z3988']")['title']
        expect(coins).to have_text 'fmt:kev:mtx:dc&rft.type=audioRecording'
      end
    end

  end
end
