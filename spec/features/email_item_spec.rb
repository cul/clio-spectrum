require 'spec_helper'

include Warden::Test::Helpers

describe 'Share by Email' do
  %w(solr_document savedlist).each do |path|
    context 'when user is logged in' do
      before do
        @autodidact = FactoryBot.build(:user, uid: 'autodidact',
                                         first_name: 'Auto',
                                         last_name: 'Didact'
                                        )
        feature_login @autodidact
        visit send("email_#{path}_path", id: 12345)
      end

      context path.to_s do
        it 'should have some instructions for the user' do
          expect(page).to have_text('Send to (comma-separated list of emails):')
          expect(page).to have_text('Message  (optional):')
        end

        it 'should email record' do
          within '#email_form' do
            fill_in 'to', with: 'marquis@columbia.edu'
            find('button[type=submit]').click
            expect(ActionMailer::Base.deliveries).not_to be_empty
          end
        end
        
      end
    end
  end

  context 'user is not logged in' do
    describe 'can email from catalog' do
      it 'should not include reply-to and name if user wishes to remain anonymous' do
        visit email_solr_document_path(id: 12345)
        within '#email_form' do
          fill_in 'to', with: 'marquis@columbia.edu'
          find('button[type=submit]').click
        end
      end
    end
    describe 'can not email from saved list' do
      it 'should redirect to root' do
        visit email_savedlist_path(id: 12345)
        expect(current_path).to eq(root_path)
      end
    end
  end
end
