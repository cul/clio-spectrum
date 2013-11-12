require 'spec_helper'

describe ItemAlertsController do

  describe "Create, Read, Update, Delete..." do

    before(:each) do
      @unpriv_user = FactoryGirl.create(:user, :login => 'persona_non_grata')
      @priv_user = FactoryGirl.create(:user, :login => 'test_manager')
    end

    it "unpriv user cannot see index" do
      login @unpriv_user
      get :index
      response.should_not be_success
      response.status.should be(302)

      # for unpriv, showing non-existant ID raises exception
      expect {
        get :show_table_row, :id => '123'
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "priv user can see index" do
      login @priv_user
      get :index
      response.should be_success
      expect(response).to render_template("index")
    end

    it "priv user can post new alert" do
      login @priv_user

      # for priv, showing non-existant ID raises exception
      expect {
        get :show_table_row, :id => '99999'
      }.to raise_error(ActiveRecord::RecordNotFound)

      # create an alert
      item_alert_attrs = FactoryGirl.attributes_for(:item_alert, :author_id => @priv_user.id)
      post :create, :item_alert => item_alert_attrs, :format => :json
      response.should be_success

      item_alert = JSON.parse(response.body)['item_alert']

      # fetch it back again, as html table row
      get :show_table_row, :id => item_alert['id']
      response.should be_success

      # fetch it back again, as raw
      get :show, :id => item_alert['id']
      response.should be_success

      # new attributes, re-post to same ID, to do an update
      item_alert_attrs = FactoryGirl.attributes_for(:item_alert, :author_id => @priv_user.id, :message => 'New Updated Message')
      put :update, :id => item_alert['id'], :item_alert => item_alert_attrs
      # success means redirect to show page for this record
      response.status.should be(302)
      response.should redirect_to(item_alert_path)

      logout

    end

  end

end

