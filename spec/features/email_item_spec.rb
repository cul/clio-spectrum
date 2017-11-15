require 'spec_helper'

include Warden::Test::Helpers

describe 'Share by Email', :vcr do
  ['solr_document', 'savedlist'].each do |path|
    context 'when user is logged in' do
      before do
        @autodidact = FactoryBot.create(:user, login: 'autodidact',
                                         first_name: 'Auto',
                                         last_name: 'Didact'
                                        )
        feature_login @autodidact
        visit self.send("email_#{path}_path", id: 12345)
      end

      context "#{path}" do
        it 'should have some instructions for the user' do
          expect(page).to have_text("Send to (comma-separated list of emails):")
          expect(page).to have_text("Your email (optional):")
          expect(page).to have_text("Your name (optional):")
          expect(page).to have_text("Message:")
        end

        it 'should email record' do
          within '#email_form' do
            fill_in 'to', with: 'marquis@columbia.edu'
            find('button[type=submit]').click
            expect(ActionMailer::Base.deliveries).not_to be_empty
          end
        end

        it 'should include reply-to and name if user includes them' do
          within '#email_form' do
            fill_in 'to', with: 'marquis@columbia.edu'
            fill_in 'reply_to', with: 'other@columbia.edu'
            fill_in 'name', with: 'Someone Else'
            fill_in 'message', with: 'testing'
            find('button[type=submit]').click
            expect(ActionMailer::Base.deliveries[0].reply_to).to eq(['other@columbia.edu'])
            expect(ActionMailer::Base.deliveries[0].to_s).to match('Someone Else')
          end
        end

        it 'should pre-fill text fields with user email and name' do
          expect(page.find("#reply_to").value).to eq('autodidact@columbia.edu')
          expect(page.find("#name").value).to eq("Auto Didact")
        end

        it 'should include default reply-to and name if user does nothing' do
          within '#email_form' do
            fill_in 'to', with: 'marquis@columbia.edu'
            find('button[type=submit]').click
            expect(ActionMailer::Base.deliveries[0].reply_to).to eq(['autodidact@columbia.edu'])
            expect(ActionMailer::Base.deliveries[0].to_s).to match('Auto Didact')
          end
        end

        it 'should allow user to change reply-to and name' do
          within '#email_form' do
            fill_in 'to', with: 'marquis@columbia.edu'
            fill_in 'reply_to', with: 'other@columbia.edu'
            fill_in 'name', with: 'Someone Else'
            find('button[type=submit]').click
            expect(ActionMailer::Base.deliveries[0].reply_to).to eq(['other@columbia.edu'])
            expect(ActionMailer::Base.deliveries[0].to_s).to match('Someone Else')
          end
        end

        it 'should not include reply-to and name if user wishes to remain anonymous' do
          within '#email_form' do
            fill_in 'to', with: 'marquis@columbia.edu'
            fill_in 'reply_to', with: ''
            fill_in 'name', with: ''
            find('button[type=submit]').click
          end
          expect(ActionMailer::Base.deliveries[0].reply_to).to be_empty
          expect(ActionMailer::Base.deliveries[0].to_s).not_to match('Auto Didact')
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
        expect(ActionMailer::Base.deliveries[0].reply_to).to be_empty
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
